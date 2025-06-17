import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/app_provider.dart';
import '../core/widgets/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memories_project/features/authentification/password/reset_password.dart';
import '../core/views/no_internet_screen.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  List<ConnectivityResult>? previousResults;

  @override
  void initState() {
    super.initState();

    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (previous, next) {
      next.whenData((connectivityResults) {
        final bool isConnected = connectivityResults.any((c) => c != ConnectivityResult.none);
        final bool wasConnected = previousResults?.any((c) => c != ConnectivityResult.none) ?? true;

        if (previousResults != null) {
          if (!isConnected) {
            _showSnackBar('Connexion perdue', Colors.red);
          } else if (!wasConnected && isConnected) {
            _showSnackBar('Connexion rétablie', Colors.green);
          }
        }

        previousResults = connectivityResults;
      });
    });
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider.select((mode) {
      if (mode.hasValue) {
        return mode.value;
      } else {
        return ThemeMode.system;
      }
    }));

    final connectivityAsync = ref.watch(connectivityProvider);

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
      themeMode: themeMode ?? ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr'),
        ],
        locale: const Locale('fr'),
        home: connectivityAsync.when(
          data: (connectivityResults) {
            final hasInternet = connectivityResults.any((c) => c != ConnectivityResult.none);

            if (!hasInternet) {
              return const NoInternetScreen();
            }

            return const Stack(
              children: [
                AuthGate(),
                ResetPasswordHandler(),
              ],
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            body: Center(child: Text('Erreur réseau : $err')),
        ),
      ),
    );
  }

}
