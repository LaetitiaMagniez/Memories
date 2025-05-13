import 'package:flutter/material.dart';
import 'package:memories_project/password/resetPassword.dart';
import 'package:provider/provider.dart';
import '../authentification/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../providers/theme_provider.dart'; // Assure-toi d’avoir ce fichier

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Memories',
            debugShowCheckedModeBanner: false,

            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),

            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),

            themeMode: themeProvider.themeMode, // Dynamique selon l'utilisateur

            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', ''),
            ],
            locale: const Locale('fr', ''),

            home: Stack(
              children: const [
                AuthGate(),
                ResetPasswordHandler(),
              ],
            ),
          );
        },
      ),
    );
  }
}