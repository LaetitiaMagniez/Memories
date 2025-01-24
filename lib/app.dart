import 'package:flutter/material.dart';
import 'package:memories_project/password/resetPassword.dart';
import 'authentification/auth_gate.dart';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          AuthGate(), // Votre page principale
          ResetPasswordHandler(), // Pour intercepter les liens
        ],
      ),
    );
  }
}