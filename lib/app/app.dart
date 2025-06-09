import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/notifiers/theme_notifier.dart';
import '../core/widgets/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memories_project/features/authentification/password/reset_password.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

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
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
      locale: const Locale('fr'),
      home: const Stack(
        children: [
          AuthGate(),
          ResetPasswordHandler(),
        ],
      ),
    );
  }
}
