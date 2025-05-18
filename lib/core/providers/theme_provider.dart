import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeFromPrefs(); // Charge le thème au démarrage
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveThemeToPrefs(mode);
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey);

    if (themeStr != null) {
      switch (themeStr) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> _saveThemeToPrefs(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
      default:
        value = 'system';
    }
    await prefs.setString(_themeKey, value);
  }
}