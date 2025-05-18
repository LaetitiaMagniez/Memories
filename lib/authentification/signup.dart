import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/services/authentification_service.dart';

import '../home.dart';

class SignUpPage extends StatefulWidget {
    const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthentificationService authentificationService = AuthentificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _showPasswordStrengthInfo = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordStrengthInfo = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Sauvegarder l'état "Se souvenir de moi" si nécessaire

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion réussie')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false,
        );
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message = "Utilisateur non trouvé.";
            break;
          case 'wrong-password':
            message = "Mot de passe incorrect.";
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

  Widget _buildPasswordCondition({required bool condition, required String text}) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: condition ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          obscureText: !_isPasswordVisible,
          onChanged: (value) {
            setState(() {
              _passwordStrength = authentificationService.calculatePasswordStrength(value);
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Veuillez entrer un mot de passe.";
            }
            if (value.length < 8) {
              return "Le mot de passe doit contenir au moins 8 caractères.";
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return "Le mot de passe doit contenir au moins un chiffre.";
            }
            if (!RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(value)) {
              return "Le mot de passe doit contenir au moins un caractère spécial.";
            }
            return null;
          },
        ),
        if (_showPasswordStrengthInfo) ...[
          SizedBox(height: 8.0),
          LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _passwordStrength < 0.5
                  ? Colors.red
                  : _passwordStrength < 0.75
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            authentificationService.getPasswordStrengthText(_passwordStrength),
            style: TextStyle(
              color: _passwordStrength < 0.5
                  ? Colors.red
                  : _passwordStrength < 0.75
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordCondition(
                condition: _passwordController.text.length >= 8,
                text: "Au moins 8 caractères",
              ),
              _buildPasswordCondition(
                condition: RegExp(r'[0-9]').hasMatch(_passwordController.text),
                text: "Contient au moins un chiffre",
              ),
              _buildPasswordCondition(
                condition: RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(_passwordController.text),
                text: "Contient au moins un caractère spécial",
              ),
            ],
          ),
        ],

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pas encore de compte ?'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                const SizedBox(height: 16),
                buildPasswordField(context),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer votre mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: () async {
                    await login(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('S\'inscrire'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
