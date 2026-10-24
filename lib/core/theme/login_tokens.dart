import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Login-only visual tokens. Change [primary] here to retheme the screen.
class LoginTokens {
  LoginTokens._();

  static const Color primary = Color(0xFF0B6B36);

  static const Color saffron = Color(0xFFFFB547);
  static const Color orange = Color(0xFFF2742B);
  static const Color deepOrange = Color(0xFFE85A1F);
  static const Color garnish = Color(0xFF2FA75A);

  static const Color textPrimary = Color(0xFF141A16);
  static const Color textSecondary = Color(0xFF5B635E);
  static const Color textMuted = Color(0xFF6B736E);
  static const Color textLabel = Color(0xFF3A423D);
  static const Color textPlaceholder = Color(0xFF9AA19C);

  static const Color inputBg = Color(0xFFF7F9F8);
  static const Color border = Color(0xFFDCE3DE);
  static const Color divider = Color(0xFFE6EBE8);
  static const Color pageBg = Color(0xFFFFFFFF);
  static const Color disabledFill = Color(0xFFE6EBE8);

  static const Color darkBg = Color(0xFF0D1210);
  static const Color darkSurface = Color(0xFF151D19);
  static const Color darkCard = Color(0xFF1A2420);
  static const Color darkBorder = Color(0xFF2C3A33);
  static const Color darkTileBorder = Color(0xFF26332D);
  static const Color darkText = Color(0xFFF2F5F3);
  static const Color darkSecondary = Color(0xFFA3ADA7);
  static const Color darkAccent = Color(0xFF3DDC84);
  static const Color darkOnAccent = Color(0xFF0D1210);

  static const double radiusControl = 16;
  static const double radiusHero = 36;
  static const double radiusTile = 12;
  static const double radiusPill = 999;
  static const double radiusFeature = 20;
  static const double minTouch = 44;
  static const double heroHeight = 340;
  static const double fieldHeight = 56;
  static const double googleHeight = 54;

  static const String termsUrl = 'https://eatepic.com/terms';
  static const String privacyUrl = 'https://eatepic.com/privacy';
}

class LoginPalette {
  const LoginPalette({
    required this.isDark,
    required this.pageBg,
    required this.surface,
    required this.card,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textLabel,
    required this.inputBg,
    required this.accent,
    required this.onAccent,
    required this.fieldFocus,
  });

  final bool isDark;
  final Color pageBg;
  final Color surface;
  final Color card;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textLabel;
  final Color inputBg;
  final Color accent;
  final Color onAccent;
  final Color fieldFocus;

  static LoginPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const LoginPalette(
        isDark: true,
        pageBg: LoginTokens.darkBg,
        surface: LoginTokens.darkSurface,
        card: LoginTokens.darkCard,
        border: LoginTokens.darkBorder,
        divider: LoginTokens.darkBorder,
        textPrimary: LoginTokens.darkText,
        textSecondary: LoginTokens.darkSecondary,
        textMuted: LoginTokens.darkSecondary,
        textLabel: LoginTokens.darkText,
        inputBg: LoginTokens.darkSurface,
        accent: LoginTokens.darkAccent,
        onAccent: LoginTokens.darkOnAccent,
        fieldFocus: LoginTokens.darkAccent,
      );
    }
    return const LoginPalette(
      isDark: false,
      pageBg: LoginTokens.pageBg,
      surface: LoginTokens.pageBg,
      card: LoginTokens.pageBg,
      border: LoginTokens.border,
      divider: LoginTokens.divider,
      textPrimary: LoginTokens.textPrimary,
      textSecondary: LoginTokens.textSecondary,
      textMuted: LoginTokens.textMuted,
      textLabel: LoginTokens.textLabel,
      inputBg: LoginTokens.inputBg,
      accent: LoginTokens.primary,
      onAccent: Colors.white,
      fieldFocus: LoginTokens.primary,
    );
  }
}

class LoginType {
  LoginType._();

  static TextStyle logo(Color color) => GoogleFonts.bricolageGrotesque(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.2,
        color: color,
      );

  static TextStyle headline(Color color, {double size = 30}) =>
      GoogleFonts.bricolageGrotesque(
        fontWeight: FontWeight.w800,
        fontSize: size,
        height: 1.12,
        letterSpacing: -0.6,
        color: color,
      );

  static TextStyle subtitle(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: color,
      );

  static TextStyle label(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 1.3,
        color: color,
      );

  static TextStyle body(Color color, {double size = 15, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: weight,
        fontSize: size,
        height: 1.3,
        color: color,
      );

  static TextStyle phone(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
        letterSpacing: 0.4,
        color: color,
      );

  static TextStyle button(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.2,
        color: color,
      );

  static TextStyle badge(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        height: 1.2,
        color: color,
      );

  static TextStyle footer(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.45,
        color: color,
      );

  static TextStyle skip(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 1.2,
        color: color,
      );

  static TextStyle divider(Color color) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.2,
        color: color,
      );
}
