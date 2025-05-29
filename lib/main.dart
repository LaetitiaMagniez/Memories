import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/widgets/auth_gate.dart';
import 'firebase_options.dart';
import 'core/providers/theme_provider.dart';
import 'dart:io';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Charger le fichier .env.android
      await dotenv.load(fileName: '.env.android');
    } catch (e, stackTrace) {
      print('Erreur lors du chargement du fichier .env.android : $e');
      print('Trace d\'appel : $stackTrace');
      // Vous pouvez également afficher un message d'erreur à l'utilisateur ici
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Erreur d\'initialisation Firebase : $e');
      // Vous pouvez également afficher un message d'erreur à l'utilisateur ici
      return;
    }

    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  }, (error, stackTrace) {
    print('Erreur non gérée : $error');
    print('Trace d\'appel : $stackTrace');
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Memories Project',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
