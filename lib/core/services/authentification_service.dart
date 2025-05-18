import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../features/user/logic/contact_service.dart';
import '../../features/user/screens/profile.dart';
import '../widgets/loading_screen.dart';

class AuthentificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContactService _contactService = ContactService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint("Erreur vérification biométrie : $e");
      return false;
    }
  }

  Future<void> saveRememberMeState(bool rememberMe, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.setString('email', email);

    if (rememberMe) {
      await _secureStorage.write(key: 'password', value: password);
    } else {
      await _secureStorage.delete(key: 'password');
    }
  }

  Future<String> loadSecurePassword() async {
    return await _secureStorage.read(key: 'password') ?? '';
  }

  Future<bool> loadRememberMeState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rememberMe') ?? false;
  }

  Future<String> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await canCheckBiometrics();

      if (isAvailable) {
        return await _localAuth.authenticate(
          localizedReason: 'Connectez-vous avec votre empreinte',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur biométrique : $e");
    }
    return false;
  }

  Future<bool> biometricLogin() async {
    final email = await loadEmail();
    final password = await loadSecurePassword();

    if (email.isEmpty || password.isEmpty) return false;

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('Erreur lors du login biométrique : $e');
      return false;
    }
  }

  Future<void> handleBiometricLogin(String email, String password) async {
    final isAvailable = await canCheckBiometrics();

    if (isAvailable) {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Enregistrer l’identifiant biométrique',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        await saveRememberMeState(true, email, password);
      }
    }
  }

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', false);
    await prefs.remove('email');
    await _secureStorage.delete(key: 'password');
    await _auth.signOut();
  }

  double calculatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score += 2;
    else if (password.length >= 6) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;
    return score / 4.0;
  }

  String getPasswordStrengthText(double passwordStrength) {
    if (passwordStrength < 0.5) return 'Mot de passe faible';
    if (passwordStrength < 0.75) return 'Mot de passe moyen';
    return 'Mot de passe fort';
  }

  Future<void> signUp(BuildContext context, String email, String password, double passwordStrength) async {
    if (passwordStrength < 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe est trop faible.')),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const LoadingScreen(message: 'Création de votre compte'),
    ));

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final uri = Uri.parse(ModalRoute.of(context)!.settings.arguments as String? ?? '');
      final code = uri.queryParameters['code'];

      if (code != null) {
        await handleInvitedSignUp(user.uid, code, email);
      } else {
        await handleRegularSignUp(user.uid, email);
      }

      await handleBiometricLogin(email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription réussie')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ProfilePage()),
            (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'email-already-in-use' => "L'email est déjà utilisé.",
        'weak-password' => "Le mot de passe est trop faible.",
        _ => "Erreur : ${e.message}"
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> handleInvitedSignUp(String userId, String code, String email) async {
    final inviteDoc = await FirebaseFirestore.instance.collection('invite_codes').doc(code).get();

    if (inviteDoc.exists) {
      final inviterUserId = inviteDoc.data()!['userId'];
      await _contactService.addFriend(userId, inviterUserId);
      await FirebaseFirestore.instance.collection('invite_codes').doc(code).delete();
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'profilePicture': null,
      'role': 'Propriétaire'
    });
  }

  Future<void> handleRegularSignUp(String userId, String email) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'profilePicture': null,
      'role': 'Propriétaire'
    });
  }
}