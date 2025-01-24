import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memories_project/app.dart';
import 'package:memories_project/firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
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
