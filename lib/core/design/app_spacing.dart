import 'package:flutter/material.dart';

/// Spacing scale — use only these values across the app.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double pill = 100;
}

abstract final class AppShadows {
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  static const BoxShadow cartBarShadow = BoxShadow(
    color: Color(0x591DB954),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow cartBarShadowDark = BoxShadow(
    color: Color(0x663DDC84),
    blurRadius: 18,
    offset: Offset(0, 4),
  );

  static const BoxShadow cardShadowDark = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow softShadowDark = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  static BoxShadow cardShadowFor(Brightness brightness) =>
      brightness == Brightness.dark ? cardShadowDark : cardShadow;

  static BoxShadow softShadowFor(Brightness brightness) =>
      brightness == Brightness.dark ? softShadowDark : softShadow;

  static BoxShadow cartBarShadowFor(Brightness brightness) =>
      brightness == Brightness.dark ? cartBarShadowDark : cartBarShadow;
}

/// Layout constants for home screen components.
abstract final class AppLayout {
  static const double appBarHeight = 56;
  static const double searchBarHeight = 48;
  static const double promoBannerHeight = 140;
  static const double cartBarHeight = 56;
  static const double bottomNavHeight = 64;
  static const double kitchenCardWidth = 180;
  static const double kitchenCardImageHeight = 105;
  static const double kitchenCardHeight = 190;
  static const double categoryImageBox = 64;
  static const double categoryImageInner = 48;
  static const double categoryChipWidth = 80;
  static const double scrollBottomInset = 120;
}
