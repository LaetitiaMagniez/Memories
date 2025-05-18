import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/user/profile.dart';
import '../transition/loading_screen.dart';
import 'contact_service.dart';

class AuthentificationService {

  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContactService _contactService = ContactService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  double _passwordStrength = 0;

  bool isLoading = false;

  // logique pour la connexion

  Future<bool> loadRememberMeState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rememberMe') ?? false;
  }

  Future<String> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  Future<String> loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password') ?? '';
  }

  Future<void> saveRememberMeState(bool rememberMe, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  // Fin partie connexion


  // Logique pour l'inscription

  void onPasswordChanged(String password) {
    _passwordStrength = calculatePasswordStrength(password);
  }
  double calculatePasswordStrength(String password) {
    int score = 0;

    // Vérifier la longueur du mot de passe
    if (password.length >= 8) {
      score += 2;
    } else if (password.length >= 6) {
      score += 1;
    }

    // Vérifier la présence de chiffres
    if (RegExp(r'[0-9]').hasMatch(password)) {
      score += 1;
    }

    // Vérifier la présence de caractères spéciaux
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score += 1;
    }

    // Normaliser le score entre 0 et 1
    return score / 4.0;
  }

  String getPasswordStrengthText(double passwordStrength) {
    if (passwordStrength < 0.5) {
      return 'Mot de passe faible';
    } else if (passwordStrength < 0.75) {
      return 'Mot de passe moyen';
    } else {
      return 'Mot de passe fort';
    }
  }

  Future<void> signUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // Récupérer la valeur de _passwordStrength pour l'afficher dans l'interface utilisateur
      double currentPasswordStrength = _passwordStrength;

      if (currentPasswordStrength < 0.5) {
        // Le mot de passe est trop faible, afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le mot de passe est trop faible. Veuillez en choisir un plus sécurisé.')),
        );
        return;
      }

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LoadingScreen(message: 'Création de votre compte'),
      ));

      try {
        // Créer l'utilisateur avec Firebase Auth
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String email = _emailController.text.trim();

        final user = userCredential.user!;

        // Vérifier si l'utilisateur a été invité via un lien unique
        final Uri uri = Uri.parse(ModalRoute.of(context)!.settings.arguments as String);
        final String? code = uri.queryParameters['code'];

        if (code != null) {
          // Cas avec code d'invitation
          await handleInvitedSignUp(user.uid, code, email);
        } else {
          // Cas classique sans code d'invitation
          await handleRegularSignUp(user.uid, email);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie')),
        );

        // Naviguer vers une autre page ou réinitialiser les champs
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => ProfilePage()),
              (Route<dynamic> route) => false,
        );
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'email-already-in-use':
            message = "L'email est déjà utilisé.";
            break;
          case 'weak-password':
            message = "Le mot de passe est trop faible.";
            break;
          default:
            message = "Une erreur est survenue : ${e.message}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }


  Future<void> handleInvitedSignUp(String userId, String code, String mail) async {
    // Vérifier si le code existe dans Firestore
    final inviteCodeDoc = await FirebaseFirestore.instance
        .collection('invite_codes')
        .doc(code)
        .get();

    if (inviteCodeDoc.exists) {
      // Récupérer l'ID de l'utilisateur qui a envoyé le lien
      final String inviterUserId = inviteCodeDoc.data()!['userId'];

      // Ajouter le nouveau compte en tant qu'ami à l'utilisateur qui a envoyé le lien
      await _contactService.addFriend(userId, inviterUserId);

      // Supprimer le code unique de Firestore
      await FirebaseFirestore.instance
          .collection('invite_codes')
          .doc(code)
          .delete();
    }

    // Ajouter l'utilisateur dans la collection Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'email': mail,
      'createdAt': FieldValue.serverTimestamp(),
      'profilePicture': null,
      'role': 'Propriétaire'
    });
  }

  Future<void> handleRegularSignUp(String userId, String mail) async {
    // Ajouter l'utilisateur dans la collection Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'email': mail,
      'createdAt': FieldValue.serverTimestamp(),
      'profilePicture': null,
      'role': 'Propriétaire'
    });
  }
}

