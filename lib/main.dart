import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifiers/theme_notifier.dart';
import 'firebase_options.dart';
import 'core/widgets/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
    } catch (e) {
      print('Erreur d\'initialisation Firebase : $e');
      return;
    }

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stackTrace) {
    print('Erreur non gérée : $error');
    print('Trace d\'appel : $stackTrace');
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestGalleryPermission();
  }

  Future<void> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied || photosStatus.isRestricted) {
        await Permission.photos.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Memories Project',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
