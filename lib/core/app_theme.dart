import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/theme/app_theme_colors.dart';

/// Brand and semantic colors.
///
/// For mode-dependent surfaces and text, prefer [AppThemeColors] via
/// `context.colors` instead of the legacy light-only aliases here.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1DB954);
  static const Color primaryLight = Color(0xFFE8F8EE);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFFABABAB);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color starColor = Color(0xFFFFC107);
  static const Color overlayDark = Color(0x8C000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE53935);

  static const Color card = background;
  static const Color border = divider;
  static const Color textMuted = textHint;
  static const Color textBody = textSecondary;
  static const Color starRating = starColor;
  static const Color searchBarBackground = surfaceGrey;
  static const Color navInactive = textHint;
  static const Color bannerBackground = Color(0xFFEDE9FE);
  static const Color bannerText = Color(0xFF7C3AED);
  static const Color darkGreen = Color(0xFF15803D);
  static const Color info = Color(0xFF2563EB);
  static const Color warning = Color(0xFFF59E0B);
  static const Color pausePurple = Color(0xFF7C3AED);
  static const Color discountOverlayBottom = overlayDark;
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        colors: AppThemeColors.light,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        colors: AppThemeColors.dark,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeColors colors,
  }) {
    final textTheme = AppTypography.textThemeFor(colors);
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: isDark ? colors.primaryOnDark : AppColors.darkGreen,
      onSecondary: AppColors.white,
      surface: colors.background,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      error: AppColors.error,
      onError: AppColors.white,
      primaryContainer: colors.primaryLight,
      onPrimaryContainer: isDark ? colors.primaryOnDark : AppColors.darkGreen,
      secondaryContainer: colors.surfaceGrey,
      onSecondaryContainer: colors.textPrimary,
      surfaceContainerHighest: colors.surfaceGrey,
      surfaceContainerHigh: colors.elevatedSurface,
      surfaceContainer: colors.card,
      outline: colors.border,
      outlineVariant: colors.divider,
      surfaceTint: Colors.transparent,
    );

    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: colors.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      applyElevationOverlayColor: false,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: [colors],
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: AppLayout.appBarHeight,
        iconTheme: IconThemeData(color: colors.textPrimary, size: 20),
        titleTextStyle: AppTypography.headingMediumFor(colors),
        systemOverlayStyle: overlay,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelBold.copyWith(fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          splashFactory: NoSplash.splashFactory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTypography.labelBold.copyWith(
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 0,
        ),
        hintStyle: AppTypography.bodyMediumFor(colors).copyWith(
          color: colors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.elevatedSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headingMediumFor(colors),
        contentTextStyle: AppTypography.bodyMediumFor(colors),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.elevatedSurface : const Color(0xFF1A1A1A),
        contentTextStyle: AppTypography.bodyMediumFor(colors).copyWith(
          color: isDark ? colors.textPrimary : AppColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textPrimary,
        textColor: colors.textPrimary,
        subtitleTextStyle: AppTypography.bodySmallFor(colors),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return colors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return colors.surfaceGrey;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return colors.textHint;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: BorderSide(color: colors.border, width: 1.5),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.elevatedSurface,
        selectedItemColor: isDark ? colors.primaryOnDark : AppColors.primary,
        unselectedItemColor: colors.navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? (isDark ? colors.primaryOnDark : AppColors.primary)
                : colors.navInactive,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.captionFor(colors).copyWith(
            fontWeight: FontWeight.w500,
            color: selected
                ? (isDark ? colors.primaryOnDark : AppColors.primary)
                : colors.navInactive,
          );
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTypography.bodyLargeFor(colors),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceGrey,
        selectedColor: colors.primaryLight,
        disabledColor: colors.surfaceGrey,
        labelStyle: AppTypography.bodySmallFor(colors),
        secondaryLabelStyle: AppTypography.bodySmallFor(colors).copyWith(
          color: isDark ? colors.primaryOnDark : AppColors.darkGreen,
        ),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      textTheme: textTheme,
    );
  }
}

/// Central typography — Poppins per design system spec.
///
/// Widget code must use `context.headingMedium` etc., not the static styles below.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Poppins';
  static const List<String> fontFamilyFallback = ['NotoSansDevanagari'];

  static TextTheme textThemeFor(AppThemeColors colors) => TextTheme(
        displayLarge: displayLargeFor(colors),
        displayMedium: displayMediumFor(colors),
        headlineLarge: headingLargeFor(colors),
        headlineMedium: headingMediumFor(colors),
        headlineSmall: headingSmallFor(colors),
        titleLarge: headingLargeFor(colors),
        titleMedium: headingMediumFor(colors),
        titleSmall: headingSmallFor(colors),
        bodyLarge: bodyLargeFor(colors),
        bodyMedium: bodyMediumFor(colors),
        bodySmall: bodySmallFor(colors),
        labelLarge: labelBold,
        labelMedium: captionFor(colors),
        labelSmall: captionFor(colors),
      );

  static TextTheme get textTheme => textThemeFor(AppThemeColors.light);

  static TextStyle displayLargeFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.2,
      );

  static TextStyle displayMediumFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.2,
      );

  static TextStyle headingLargeFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.25,
      );

  static TextStyle headingMediumFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.25,
      );

  static TextStyle headingSmallFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.25,
      );

  static TextStyle bodyLargeFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
        height: 1.35,
      );

  static TextStyle bodyMediumFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
        height: 1.35,
      );

  static TextStyle bodySmallFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colors.textHint,
        height: 1.35,
      );

  static TextStyle captionFor(AppThemeColors colors) => TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
        height: 1.2,
      );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.35,
  );

  static const TextStyle labelBold = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle titleLarge = headingLarge;
  static const TextStyle titleMedium = headingMedium;
  static const TextStyle titleSmall = headingSmall;
  static const TextStyle headlineLarge = headingLarge;
  static const TextStyle headlineMedium = headingMedium;
  static const TextStyle headlineSmall = headingSmall;
  static const TextStyle displaySmall = displayMedium;
  static const TextStyle labelLarge = labelBold;
  static const TextStyle labelMedium = caption;
  static const TextStyle labelSmall = caption;
}

extension AppTypographyContext on BuildContext {
  AppThemeColors get colors => Theme.of(this).extension<AppThemeColors>()!;

  TextStyle get displayLarge => AppTypography.displayLargeFor(colors);
  TextStyle get displayMedium => AppTypography.displayMediumFor(colors);
  TextStyle get headingLarge => AppTypography.headingLargeFor(colors);
  TextStyle get headingMedium => AppTypography.headingMediumFor(colors);
  TextStyle get headingSmall => AppTypography.headingSmallFor(colors);
  TextStyle get bodyLarge => AppTypography.bodyLargeFor(colors);
  TextStyle get bodyMedium => AppTypography.bodyMediumFor(colors);
  TextStyle get bodySmall => AppTypography.bodySmallFor(colors);
  TextStyle get caption => AppTypography.captionFor(colors);
}
