import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';

/// Theme-aware home text styles.
extension AppTextStyles on BuildContext {
  TextStyle get homeLocationTitle => headingMedium;

  TextStyle get homeAddressSubtitle =>
      bodySmall.copyWith(color: colors.textSecondary);

  TextStyle get searchPlaceholder =>
      bodyMedium.copyWith(color: colors.textHint);

  TextStyle get sectionHeading => headingMedium;
  TextStyle get sectionHeadingLarge => headingMedium;

  TextStyle get bannerTitle => displayMedium.copyWith(
        color: colors.bannerText,
        fontWeight: FontWeight.w800,
      );

  TextStyle get bannerSubtitle =>
      bodySmall.copyWith(color: colors.textSecondary);

  TextStyle get bannerFinePrint => caption;

  TextStyle get categoryChipLabel => bodySmall.copyWith(
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
      );

  TextStyle get restaurantName => headingSmall;
  TextStyle get restaurantNameSmall => headingSmall;

  TextStyle get ratingRow =>
      bodySmall.copyWith(color: colors.textSecondary);

  TextStyle get ratingRowSmall =>
      bodySmall.copyWith(color: colors.textSecondary);

  TextStyle get discountOverlay => AppTypography.labelBold;

  TextStyle get cartBarText =>
      AppTypography.labelBold.copyWith(fontSize: 13);

  TextStyle get cartBarAction =>
      AppTypography.labelBold.copyWith(fontSize: 14);

  TextStyle get bottomNavSelected => caption.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(this).brightness == Brightness.dark
            ? colors.primaryOnDark
            : AppColors.primary,
      );

  TextStyle get bottomNavUnselected => caption.copyWith(
        fontWeight: FontWeight.w500,
        color: colors.navInactive,
      );
}
