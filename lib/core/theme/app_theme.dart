import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'typography.dart';

/// Main theme configuration for LGBTFinder app
/// Supports both light and dark modes
class AppTheme {
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      primaryColor: AppColors.accentPurple,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accentPurple,
        secondary: AppColors.accentPink,
        surface: AppColors.surfaceDark,
        error: AppColors.notificationRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onError: Colors.white,
      ),
      textTheme: AppTypography.textThemeDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.light,
      primaryColor: AppColors.accentPurple,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.accentPurple,
        secondary: AppColors.accentPink,
        surface: AppColors.surfaceLight,
        error: AppColors.notificationRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),
      textTheme: AppTypography.textThemeLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
    );
  }

  // Gradient Helper
  static LinearGradient get accentGradient => LinearGradient(
    colors: [AppColors.accentGradientStart, AppColors.accentGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Splash screen rainbow gradient — sourced from [AppColors.lgbtGradient].
  static const List<Color> splashGradientColors = AppColors.lgbtGradient;

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: splashGradientColors,
    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
  );
}

