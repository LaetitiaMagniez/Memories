import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeNotifierProvider = AsyncNotifierProvider<ThemeAsyncNotifier, ThemeMode>(
  ThemeAsyncNotifier.new,
);

class ThemeAsyncNotifier extends AsyncNotifier<ThemeMode> {
  static const _themeKey = 'theme_mode';
  late SharedPreferences _prefs;

  @override
  Future<ThemeMode> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _loadThemeFromPrefs();
  }

  ThemeMode _loadThemeFromPrefs() {
    final themeStr = _prefs.getString(_themeKey);
    return _stringToThemeMode(themeStr);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    await _prefs.setString(_themeKey, _themeModeToString(mode));
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
