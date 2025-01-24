import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/authentification/auth_gate.dart';

class ResetPasswordHandler extends StatefulWidget {
  @override
  _ResetPasswordHandlerState createState() => _ResetPasswordHandlerState();
}

class _ResetPasswordHandlerState extends State<ResetPasswordHandler> {
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
      // Analyser l'URL complète de Firebase
      final parsedUri = Uri.parse(uri.toString());
      
      if (parsedUri.path.contains('/resetPassword') && 
          parsedUri.queryParameters['mode'] == 'resetPassword') {
        
        final oobCode = parsedUri.queryParameters['oobCode'];
        
          if (oobCode != null) {
            _navigateToResetPasswordPage(oobCode);
          }
        }
      }
    });
  }

  void _navigateToResetPasswordPage(String oobCode) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ResetPasswordPage(oobCode: oobCode),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Ce widget peut être vide car il gère uniquement les liens entrants
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String oobCode;

  ResetPasswordPage({required this.oobCode});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false; 

  Future<void> _resetPassword() async {
  if (_passwordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Les mots de passe ne correspondent pas')),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.confirmPasswordReset(
      code: widget.oobCode,
      newPassword: _passwordController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mot de passe réinitialisé avec succès')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthGate()),
      (Route<dynamic> route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la réinitialisation du mot de passe : ${e.toString()}')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Réinitialiser votre mot de passe')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe :',
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
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Enregistrer mon nouveau mot de passe'),
            ),
          ],
        ),
      ),
    );
  }
}
