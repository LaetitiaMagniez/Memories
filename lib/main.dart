import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/widgets/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'core/providers/app_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR', null);

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
      const ProviderScope(child: MyApp()),
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
    final connectivityAsync = ref.watch(connectivityProvider);
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    final themeModeAsync = ref.watch(themeNotifierProvider);

    return prefsAsync.when(
      data: (prefs) {
        return connectivityAsync.when(
          data: (connectivityResult) {
            final isConnected = connectivityResult != ConnectivityResult.none;

            return themeModeAsync.when(
              data: (themeMode) {
                if (!isConnected) {
                  return MaterialApp(
                    title: 'Memories Project',
                    theme: ThemeData.light(),
                    darkTheme: ThemeData.dark(),
                    themeMode: themeMode,
                    home: Scaffold(
                      appBar: AppBar(title: const Text('Pas de connexion')),
                      body: const Center(
                        child: Text(
                          'Veuillez vérifier votre connexion internet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    debugShowCheckedModeBanner: false,
                    localizationsDelegates: GlobalMaterialLocalizations.delegates,
                    supportedLocales: const [Locale('fr', 'FR')],
                  );
                }

                return MaterialApp(
                  title: 'Memories Project',
                  theme: ThemeData.light(),
                  darkTheme: ThemeData.dark(),
                  themeMode: themeMode,
                  home: const AuthGate(),
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  supportedLocales: const [Locale('fr', 'FR')],
                );
              },
              loading: () => const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => MaterialApp(
                home: Scaffold(
                  body: Center(child: Text('Erreur de thème : $err')),
                ),
              ),
            );
          },
          loading: () => const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (err, _) => MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Erreur de connexion : $err')),
            ),
          ),
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Erreur de chargement : $err')),
        ),
      ),
    );
  }
}
