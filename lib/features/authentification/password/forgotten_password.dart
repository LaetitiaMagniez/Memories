import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgottenPasswordPage extends StatefulWidget {
  const ForgottenPasswordPage({super.key});

  @override
  _ForgottenPasswordPage createState() => _ForgottenPasswordPage();
}

class _ForgottenPasswordPage extends State<ForgottenPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  void _showCustomSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showCustomSnackBar('Un e-mail de réinitialisation a été envoyé');
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showCustomSnackBar('Erreur : ${e.message}', color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre adresse e-mail';
    }
    final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Adresse e-mail invalide';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialisation du mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Envoyer le lien de réinitialisation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}