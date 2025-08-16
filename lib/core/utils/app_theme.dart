import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'constants.dart';

/// Comprehensive theme configuration for PawSense application
/// Uses our custom AppColors and constants throughout
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: kFontFamily,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.info,
        onSecondary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.background,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(kShadowOpacity),
        titleTextStyle: kTextStyleTitle.copyWith(
          color: AppColors.textPrimary,
        ),
        toolbarTextStyle: kTextStyleRegular.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textSecondary,
          size: kIconSizeLarge,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(kShadowOpacity),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        margin: EdgeInsets.all(kSpacingSmall),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(kShadowOpacity * 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: kSpacingMedium,
            vertical: kSpacingMedium,
          ),
          textStyle: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: Size(0, kButtonHeight),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: kTextStyleRegular,
          padding: EdgeInsets.symmetric(
            horizontal: kSpacingMedium,
            vertical: kSpacingSmall,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: kSpacingMedium,
            vertical: kSpacingMedium,
          ),
          textStyle: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: Size(0, kButtonHeight),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: kSpacingMedium,
          vertical: kSpacingMedium,
        ),
        labelStyle: kTextStyleRegular.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: kTextStyleRegular.copyWith(
          color: AppColors.textTertiary,
        ),
        errorStyle: kTextStyleSmall.copyWith(
          color: AppColors.error,
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: kIconSizeMedium,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: kTextStyleHeader.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineMedium: kTextStyleTitle.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineSmall: kTextStyleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: kTextStyleRegular.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: kTextStyleRegular.copyWith(
          color: AppColors.textSecondary,
        ),
        bodySmall: kTextStyleSmall.copyWith(
          color: AppColors.textSecondary,
        ),
        labelLarge: kTextStyleRegular.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: kTextStyleSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: kTextStyleSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: kSpacingMedium,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.border;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.white;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusSmall / 2),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: kTextStyleRegular.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(kShadowOpacity * 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        titleTextStyle: kTextStyleTitle.copyWith(
          color: AppColors.textPrimary,
        ),
        contentTextStyle: kTextStyleRegular.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // For now, return a simple dark variant
    // TODO: Implement comprehensive dark theme with proper dark colors
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
    );
  }
}

/// Extension to provide theme-aware color access
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}
