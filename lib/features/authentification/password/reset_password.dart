import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/features/authentification/screens/auth_tabs.dart';

class ResetPasswordHandler extends StatefulWidget {
  const ResetPasswordHandler({super.key});

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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResetPasswordPage(oobCode: oobCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(); // Ce widget peut rester vide
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String oobCode;

  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
    if (_passwordController.text != _confirmPasswordController.text) {
      _showCustomSnackBar('Les mots de passe ne correspondent pas', color: Colors.red);
      return;
    }

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: _passwordController.text,
      );

      _showCustomSnackBar('Mot de passe réinitialisé avec succès');

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthTabs(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeInOut));
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation.drive(tween), child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showCustomSnackBar('Erreur : ${e.toString()}', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialiser votre mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              obscureText: !_isPasswordVisible,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmer votre mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
              ),
              obscureText: !_isConfirmPasswordVisible,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Enregistrer mon nouveau mot de passe'),
            ),
          ],
        ),
      ),
    );
  }
}