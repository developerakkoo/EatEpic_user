import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/theme/app_theme_colors.dart';

void main() {
  test('dark palette uses EatEpic green-black surfaces, not Material grey', () {
    const dark = AppThemeColors.dark;

    expect(dark.background, const Color(0xFF0B1410));
    expect(dark.card, const Color(0xFF15241C));
    expect(dark.elevatedSurface, const Color(0xFF15241C));
    expect(dark.surfaceGrey, const Color(0xFF1C2E24));
    expect(dark.searchBarBackground, const Color(0xFF1C2E24));
    expect(dark.divider, const Color(0xFF2A3F34));
    expect(dark.border, const Color(0xFF2A3F34));
    expect(dark.textPrimary, const Color(0xFFF2F7F4));
    expect(dark.textSecondary, const Color(0xFFA8C4B4));
    expect(dark.textHint, const Color(0xFF6E8A7C));
    expect(dark.navInactive, const Color(0xFF6E8A7C));
    expect(dark.primaryLight, const Color(0xFF163326));
    expect(dark.bannerBackground, const Color(0xFF231C38));
    expect(dark.bannerText, const Color(0xFFC4B5FD));
    expect(dark.primaryOnDark, const Color(0xFF3DDC84));
  });

  test('light palette stays white canvas with mint wash', () {
    const light = AppThemeColors.light;

    expect(light.background, const Color(0xFFFFFFFF));
    expect(light.card, const Color(0xFFFFFFFF));
    expect(light.primaryLight, const Color(0xFFE8F8EE));
    expect(light.bannerText, const Color(0xFF7C3AED));
    expect(light.primaryOnDark, const Color(0xFF1DB954));
  });

  testWidgets('dark ThemeData inherits brand surfaces instead of default Material',
      (tester) async {
    late ColorScheme scheme;
    late AppThemeColors colors;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            colors = context.colors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(ThemeData.estimateBrightnessForColor(colors.background), Brightness.dark);
    expect(colors.background, const Color(0xFF0B1410));
    expect(scheme.surface, colors.background);
    expect(scheme.surfaceContainer, colors.card);
    expect(scheme.primaryContainer, colors.primaryLight);
    expect(scheme.outline, colors.border);
    expect(scheme.surfaceTint, Colors.transparent);
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, colors.background);
    expect(AppTheme.darkTheme.dialogTheme.backgroundColor, colors.elevatedSurface);
    expect(AppTheme.darkTheme.applyElevationOverlayColor, isFalse);
  });

  testWidgets('light ThemeData keeps a white canvas', (tester) async {
    late AppThemeColors colors;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (context) {
            colors = context.colors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(colors.background, const Color(0xFFFFFFFF));
    expect(AppTheme.lightTheme.scaffoldBackgroundColor, colors.background);
    expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primary);
  });
}
