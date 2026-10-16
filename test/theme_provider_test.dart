import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/provider/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('load uses light mode by default', () async {
      final provider = ThemeProvider();
      await provider.load();

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.hasSelectedTheme, false);
    });

    test('setThemeMode persists selection', () async {
      final provider = ThemeProvider();
      await provider.setThemeMode(ThemeMode.dark, markSelected: true);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.hasSelectedTheme, true);

      final reloaded = ThemeProvider();
      await reloaded.load();
      expect(reloaded.themeMode, ThemeMode.dark);
      expect(reloaded.hasSelectedTheme, true);
    });

    test('labelForMode returns translation keys', () {
      expect(ThemeProvider.labelForMode(ThemeMode.light), 'theme.light');
      expect(ThemeProvider.labelForMode(ThemeMode.dark), 'theme.dark');
      expect(ThemeProvider.labelForMode(ThemeMode.system), 'theme.system');
    });
  });
}
