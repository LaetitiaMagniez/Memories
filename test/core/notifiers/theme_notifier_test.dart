import 'package:flutter_test/flutter_test.dart';
import 'package:memories_project/core/notifiers/theme_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class FakeSharedPreferences extends Fake implements SharedPreferences {
  final Map<String, Object> _values = {};

  @override
  String? getString(String key) {
    final value = _values[key];
    if (value is String) return value;
    return null;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }
}

void main() {
  late FakeSharedPreferences fakePrefs;
  late ThemeNotifier themeNotifier;

  setUp(() {
    fakePrefs = FakeSharedPreferences();
  });

  test('initial state is system if no saved preference', () {
    // Pas de valeur dans fakePrefs
    themeNotifier = ThemeNotifier(fakePrefs);

    expect(themeNotifier.state, ThemeMode.system);
  });

  test('loads light theme from prefs', () {
    fakePrefs._values['theme_mode'] = 'light';

    themeNotifier = ThemeNotifier(fakePrefs);

    expect(themeNotifier.state, ThemeMode.light);
  });

  test('loads dark theme from prefs', () {
    fakePrefs._values['theme_mode'] = 'dark';

    themeNotifier = ThemeNotifier(fakePrefs);

    expect(themeNotifier.state, ThemeMode.dark);
  });

  test('setThemeMode updates state and saves to prefs', () async {
    themeNotifier = ThemeNotifier(fakePrefs);

    await themeNotifier.setThemeMode(ThemeMode.dark);

    expect(themeNotifier.state, ThemeMode.dark);
    expect(fakePrefs.getString('theme_mode'), 'dark');
  });
}
