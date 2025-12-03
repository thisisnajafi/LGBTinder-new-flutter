import 'package:flutter/material.dart';

/// Typography system for LGBTinder app
class AppTypography {
  // Headlines
  static const TextStyle h1Large = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  // Special Styles
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static const TextStyle displayScript = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.5,
    height: 1.1,
  );

  // Text Themes
  static TextTheme get textThemeDark => TextTheme(
    displayLarge: h1Large.copyWith(color: Colors.white),
    displayMedium: h1.copyWith(color: Colors.white),
    displaySmall: h2.copyWith(color: Colors.white),
    headlineMedium: h3.copyWith(color: Colors.white),
    bodyLarge: bodyLarge.copyWith(color: Colors.white),
    bodyMedium: body.copyWith(color: Colors.white),
    bodySmall: bodySmall.copyWith(color: const Color(0xFFA6A6A6)),
    labelLarge: button.copyWith(color: Colors.white),
  );

  static TextTheme get textThemeLight => TextTheme(
    displayLarge: h1Large.copyWith(color: Colors.black),
    displayMedium: h1.copyWith(color: Colors.black),
    displaySmall: h2.copyWith(color: Colors.black),
    headlineMedium: h3.copyWith(color: Colors.black),
    bodyLarge: bodyLarge.copyWith(color: Colors.black),
    bodyMedium: body.copyWith(color: Colors.black),
    bodySmall: bodySmall.copyWith(color: const Color(0xFF6B6B6B)),
    labelLarge: button.copyWith(color: Colors.black),
  );
}

