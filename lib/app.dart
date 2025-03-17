import 'package:flutter/material.dart';
import 'package:memories_project/password/resetPassword.dart';
import 'authentification/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          AuthGate(), // Votre page principale
          ResetPasswordHandler(), // Pour intercepter les liens
        ],
      ),
       localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('fr', ''), // Français
      ],
      locale: const Locale('fr', ''), // Forcer l'application en français
      // ... le reste de votre configuration MaterialApp
    );
  }
}