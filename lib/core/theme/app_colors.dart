import 'package:flutter/material.dart';

/// Color definitions for LGBTFinder app
/// Supports both dark and light modes
class AppColors {
  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0B0B0D);
  static const Color surfaceDark = Color(0xFF121214);
  static const Color surfaceElevatedDark = Color(0xFF1A1A1C);
  
  // Accent Colors
  static const Color accentPurple = Color(0xFF8A2BE2);
  static const Color accentGradientStart = Color(0xFF7B2BE2);
  static const Color accentGradientEnd = Color(0xFFD33CFF);
  static const Color accentPink = Color(0xFFFF3CA6);
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color accentRed = Color(0xFFFF3B30);
  
  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA6A6A6);
  static const Color textTertiaryDark = Color(0xFF6B6B6B);
  
  // Status & Indicators
  static const Color onlineGreen = Color(0xFF2ECC71);
  static const Color notificationRed = Color(0xFFFF3B30);
  static const Color warningYellow = Color(0xFFFFC107);
  
  // Light Mode Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F7);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  
  // Text Colors - Light Mode
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textTertiaryLight = Color(0xFF9B9B9B);
  
  // Borders & Dividers - Dark Mode
  static Color borderSubtleDark = const Color.fromRGBO(255, 255, 255, 0.04);
  static Color borderMediumDark = const Color.fromRGBO(255, 255, 255, 0.08);
  static Color dividerDark = const Color.fromRGBO(255, 255, 255, 0.06);
  
  // Borders & Dividers - Light Mode
  static Color borderSubtleLight = const Color.fromRGBO(0, 0, 0, 0.08);
  static Color borderMediumLight = const Color.fromRGBO(0, 0, 0, 0.12);
  static Color dividerLight = const Color.fromRGBO(0, 0, 0, 0.1);

  // LGBT / Pride gradient (softer palette matching landing page header logo)
  static const List<Color> lgbtGradient = [
    Color(0xFFD62828), // red
    Color(0xFFE76F51), // orange
    Color(0xFFE9C46A), // yellow/gold
    Color(0xFF2A9D8F), // green
    Color(0xFF457B9D), // blue
    Color(0xFF6A4C93), // violet
  ];

  static const LinearGradient prideGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: lgbtGradient,
    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
  );
}

