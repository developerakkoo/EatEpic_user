import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.surfaceGrey,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.divider,
    required this.primaryLight,
    required this.bannerBackground,
    required this.searchBarBackground,
    required this.card,
    required this.border,
    required this.navInactive,
    required this.elevatedSurface,
    required this.primaryOnDark,
    required this.bannerText,
  });

  final Color background;
  final Color surfaceGrey;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color divider;
  final Color primaryLight;
  final Color bannerBackground;
  final Color searchBarBackground;
  final Color card;
  final Color border;
  final Color navInactive;
  final Color elevatedSurface;
  final Color primaryOnDark;
  final Color bannerText;

  static const light = AppThemeColors(
    background: Color(0xFFFFFFFF),
    surfaceGrey: Color(0xFFF5F5F5),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    textHint: Color(0xFFABABAB),
    divider: Color(0xFFEEEEEE),
    primaryLight: Color(0xFFE8F8EE),
    bannerBackground: Color(0xFFEDE9FE),
    searchBarBackground: Color(0xFFF5F5F5),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFEEEEEE),
    navInactive: Color(0xFFABABAB),
    elevatedSurface: Color(0xFFFFFFFF),
    primaryOnDark: Color(0xFF1DB954),
    bannerText: Color(0xFF7C3AED),
  );

  static const dark = AppThemeColors(
    background: Color(0xFF0B1410),
    surfaceGrey: Color(0xFF1C2E24),
    textPrimary: Color(0xFFF2F7F4),
    textSecondary: Color(0xFFA8C4B4),
    textHint: Color(0xFF6E8A7C),
    divider: Color(0xFF2A3F34),
    primaryLight: Color(0xFF163326),
    bannerBackground: Color(0xFF231C38),
    searchBarBackground: Color(0xFF1C2E24),
    card: Color(0xFF15241C),
    border: Color(0xFF2A3F34),
    navInactive: Color(0xFF6E8A7C),
    elevatedSurface: Color(0xFF15241C),
    primaryOnDark: Color(0xFF3DDC84),
    bannerText: Color(0xFFC4B5FD),
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surfaceGrey,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? divider,
    Color? primaryLight,
    Color? bannerBackground,
    Color? searchBarBackground,
    Color? card,
    Color? border,
    Color? navInactive,
    Color? elevatedSurface,
    Color? primaryOnDark,
    Color? bannerText,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surfaceGrey: surfaceGrey ?? this.surfaceGrey,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      divider: divider ?? this.divider,
      primaryLight: primaryLight ?? this.primaryLight,
      bannerBackground: bannerBackground ?? this.bannerBackground,
      searchBarBackground: searchBarBackground ?? this.searchBarBackground,
      card: card ?? this.card,
      border: border ?? this.border,
      navInactive: navInactive ?? this.navInactive,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      primaryOnDark: primaryOnDark ?? this.primaryOnDark,
      bannerText: bannerText ?? this.bannerText,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surfaceGrey: Color.lerp(surfaceGrey, other.surfaceGrey, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      bannerBackground: Color.lerp(bannerBackground, other.bannerBackground, t)!,
      searchBarBackground:
          Color.lerp(searchBarBackground, other.searchBarBackground, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      navInactive: Color.lerp(navInactive, other.navInactive, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      primaryOnDark: Color.lerp(primaryOnDark, other.primaryOnDark, t)!,
      bannerText: Color.lerp(bannerText, other.bannerText, t)!,
    );
  }
}
