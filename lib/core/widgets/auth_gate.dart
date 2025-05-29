import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memories_project/core/services/authentification_service.dart';
import 'package:memories_project/app/home.dart';
import '../../features/authentification/screens/auth_tabs.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = FirebaseAuth.instance;
  final _authService = AuthentificationService();

  @override
  void initState() {
    super.initState();
    _handleRedirect();
  }

  Future<void> _handleRedirect() async {
    final user = _auth.currentUser;

    if (kIsWeb) {
      if (user != null) {
        _goTo(const HomeScreen());
      } else {
        _goTo(const AuthTabs());
      }
      return;
    }

    if (user != null) {
      _goTo(const HomeScreen());
    } else {
      final rememberMe = await _authService.loadRememberMeState();
      if (rememberMe) {
        final didAuth = await _authService.authenticateWithBiometrics();
        if (didAuth) {
          final success = await _authService.biometricLogin();
          if (success) {
            _goTo(const HomeScreen());
            return;
          }
        }
      }
      _goTo(const AuthTabs());
    }
  }

  void _goTo(Widget screen) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
