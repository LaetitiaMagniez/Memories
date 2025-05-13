import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/screens/app.dart';
import 'package:memories_project/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Erreur d\'initialisation Firebase : $e');
    }
    
    runApp(MyApp());
  }, (error, stackTrace) {
    print('Erreur non gérée : $error');
  });
}
