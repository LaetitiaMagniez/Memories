import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memories_project/transition/loadingScreen.dart';
import 'package:memories_project/screens/user/profile.dart';


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

      final user = userCredential.user!;
      
        // Ajouter l'utilisateur dans la collection Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'profilePicture': null, // Valeur par défaut pour l'icône utilisateur
        });

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
