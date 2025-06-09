import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _themeKey = 'theme_mode';
  final SharedPreferences prefs;

  ThemeNotifier(this.prefs) : super(ThemeMode.system) {
    _loadThemeFromPrefs();
  }

  void _loadThemeFromPrefs() {
    final themeStr = prefs.getString(_themeKey);
    state = _stringToThemeMode(themeStr);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await prefs.setString(_themeKey, _themeModeToString(mode));
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String? str) {
    switch (str) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

// Provider pour SharedPreferences (asynchrone)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// Provider du ThemeNotifier qui dépend de SharedPreferences
final themeNotifierProvider =
StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);

  return prefsAsync.when(
    data: (prefs) => ThemeNotifier(prefs),
    loading: () => ThemeNotifier(
      // ici, tu peux fournir une instance fictive ou SharedPreferences.getInstance() synchronisé si tu en as une,
      // ou créer un constructeur ThemeNotifier vide si tu veux gérer ce cas.
        throw UnimplementedError('SharedPreferences not ready')),
    error: (_, __) => ThemeNotifier(
        throw UnimplementedError('Error loading SharedPreferences')),
  );
});
