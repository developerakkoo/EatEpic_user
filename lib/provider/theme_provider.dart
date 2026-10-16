import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyThemeMode = 'theme_mode';
const String _keyThemeSelected = 'theme_selected';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _hasSelectedTheme = false;

  ThemeMode get themeMode => _themeMode;
  bool get hasSelectedTheme => _hasSelectedTheme;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSelectedTheme = prefs.getBool(_keyThemeSelected) ?? false;
    _themeMode = _parseThemeMode(prefs.getString(_keyThemeMode));
  }

  Future<void> setThemeMode(
    ThemeMode mode, {
    required bool markSelected,
  }) async {
    _themeMode = mode;
    if (markSelected) {
      _hasSelectedTheme = true;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _encodeThemeMode(mode));
    if (markSelected) {
      await prefs.setBool(_keyThemeSelected, true);
    }
    notifyListeners();
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  static String labelForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'theme.dark';
      case ThemeMode.system:
        return 'theme.system';
      case ThemeMode.light:
        return 'theme.light';
    }
  }
}
