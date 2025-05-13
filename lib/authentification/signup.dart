import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memories_project/service/contact_service.dart';
import 'package:memories_project/transition/loadingScreen.dart';
import 'package:memories_project/screens/user/profile.dart';
import 'package:memories_project/service/profile_service.dart';



class SignUpPage extends StatefulWidget {
    const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false; 
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContactService _contactService = ContactService();


  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LoadingScreen(message: 'Création de votre compte'),
      ));

      try {
        // Créer l'utilisateur avec Firebase Auth
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String email =_emailController.text.trim();

        final user = userCredential.user!;

        // Vérifier si l'utilisateur a été invité via un lien unique
        final Uri uri = Uri.parse(ModalRoute.of(context)!.settings.arguments as String);
        final String? code = uri.queryParameters['code'];

        if (code != null) {
          // Cas avec code d'invitation
          await _handleInvitedSignUp(user.uid, code, email);
        } else {
          // Cas classique sans code d'invitation
          await _handleRegularSignUp(user.uid,email);
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
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleInvitedSignUp(String userId, String code, String mail) async {
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

  Future<void> _handleRegularSignUp(String userId, String mail) async {
    // Ajouter l'utilisateur dans la collection Firestore
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'email': mail,
      'createdAt': FieldValue.serverTimestamp(),
      'profilePicture': null,
      'role': 'Propriétaire'
    });
  }

  Future<void> _addFriendToUser(String userId, String inviterUserId) async {
    // Ajouter le nouveau compte en tant qu'ami à l'utilisateur qui a envoyé le lien
    await FirebaseFirestore.instance
        .collection('users')
        .doc(inviterUserId)
        .collection('friends')
        .doc(userId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }


        @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pas encore de compte ? Inscrivez-vous'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez entrer un email.";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Veuillez entrer un email valide.";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez entrer un mot de passe.";
                }
                if (value.length < 6) {
                  return "Le mot de passe doit contenir au moins 6 caractères.";
                }
                return null;
              },
              ),
              SizedBox(height: 16.0),
              TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmer votre mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isConfirmPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Veuillez confirmer votre mot de passe.";
                }
                if (value != _passwordController.text) {
                  return "Les mots de passe ne correspondent pas.";
                }
                return null;
              },
              ),

              SizedBox(height: 24),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      child: Text("S'inscrire")
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
