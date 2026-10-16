import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';

/// Layout and brand tokens for home screens. Semantic colors live on
/// [HomeDesignTokensX].
abstract final class HomeDesignTokens {
  static const Color primaryGreen = AppColors.primary;
  static const Color starGold = AppColors.starColor;
  static const Color starAmber = AppColors.starColor;
  static const Color notificationDot = AppColors.error;
  static const Color discountBadgeBg = AppColors.overlayDark;

  static const double horizontalPadding = AppSpacing.lg;
  static const double sectionGap = AppSpacing.xl;
  static const double searchVertical = AppSpacing.sm;
  static const double cardGap = AppSpacing.md;
  static const double promoPeek = AppSpacing.sm;

  static const double radiusSearch = AppRadius.medium;
  static const double radiusCard = AppRadius.large;
  static const double kitchenCardRadius = AppRadius.medium;
  static const double radiusCategory = AppRadius.medium;
  static const double radiusCartBar = AppRadius.large;

  static const double searchHeight = AppLayout.searchBarHeight;
  static const double promoHeight = AppLayout.promoBannerHeight;
  static const double categoryRowHeight = 96;
  static const double categoryTileSize = AppLayout.categoryImageBox;
  static const double cartBarHeight = AppLayout.cartBarHeight;
  static const double toolbarHeight = AppLayout.appBarHeight;
  static const double kitchenImageHeightHorizontal = AppLayout.kitchenCardImageHeight;
  static const double kitchenImageHeightVertical = 160;
  static const double kitchenCardWidthHorizontal = AppLayout.kitchenCardWidth;
  static const double kitchenCardInfoHeight = 85;
  static const double kitchenCardHeightHorizontal = AppLayout.kitchenCardHeight;
  static const double scrollBottomPadding = AppLayout.scrollBottomInset;

  static const String fontFamily = AppTypography.fontFamily;
}

extension HomeDesignTokensX on BuildContext {
  Color get pageBg => colors.background;
  Color get surfaceMuted => colors.surfaceGrey;
  Color get homeTextPrimary => colors.textPrimary;
  Color get textBody => colors.textSecondary;
  Color get textMuted => colors.textHint;
  Color get borderLight => colors.divider;
  Color get bannerPurpleBg => colors.bannerBackground;
  Color get bannerPurpleText => colors.bannerText;
  Color get navInactive => colors.navInactive;

  TextStyle get kitchenCardNameText => headingSmall;
  TextStyle get kitchenCardMetaText => bodySmall;
  TextStyle get kitchenDiscountBadgeText => AppTypography.labelBold;
}
