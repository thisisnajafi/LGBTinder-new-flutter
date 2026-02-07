import 'package:flutter/material.dart';

/// Unified color system for LGBTFinder app
/// Aligned with the marketing website (lgbtinder-landing) so app and web feel like one brand.
///
/// **Light mode** = Website hero/sections: white + zinc neutrals + rose/violet accents.
/// **Dark mode** = Website footer + same accents: zinc-900 base, rose/violet for CTAs.
///
/// Palette source: Tailwind zinc (neutrals), rose (primary accent), violet (secondary).
class AppColors {
  // ─── Light mode (matches landing: hero, features, header) ─────────────────
  /// Page background — white (landing body/hero)
  static const Color backgroundLight = Color(0xFFFFFFFF);
  /// Cards, list tiles — zinc-50/100 (landing gradients: to-zinc-50)
  static const Color surfaceLight = Color(0xFFFAFAFA);
  /// Modals, dropdowns — elevated white
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  /// Primary text — zinc-900 (landing headings, body)
  static const Color textPrimaryLight = Color(0xFF18181B);
  /// Secondary text — zinc-600 (landing body/secondary)
  static const Color textSecondaryLight = Color(0xFF52525B);
  /// Muted / captions — zinc-500
  static const Color textTertiaryLight = Color(0xFF71717A);

  /// Borders — zinc-200 (landing header, features borders)
  static Color borderSubtleLight = const Color(0xFFE4E4E7);
  static Color borderMediumLight = const Color(0xFFD4D4D8);
  static Color dividerLight = const Color(0xFFE4E4E7);

  // ─── Dark mode (matches landing footer: zinc-900 + zinc-300/400 text) ─────────
  /// Page background — zinc-900 (landing footer bg)
  static const Color backgroundDark = Color(0xFF18181B);
  /// Cards, list tiles — zinc-800
  static const Color surfaceDark = Color(0xFF27272A);
  /// Modals, dropdowns — zinc-700
  static const Color surfaceElevatedDark = Color(0xFF3F3F46);

  /// Primary text — white
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  /// Secondary text — zinc-300 (landing footer links)
  static const Color textSecondaryDark = Color(0xFFD4D4D8);
  /// Muted — zinc-400
  static const Color textTertiaryDark = Color(0xFFA1A1AA);

  /// Borders — zinc-700/600
  static Color borderSubtleDark = const Color(0xFF3F3F46);
  static Color borderMediumDark = const Color(0xFF52525B);
  static Color dividerDark = const Color(0xFF3F3F46);

  // ─── Brand accents (landing: rose + violet) ───────────────────────────────
  /// Primary CTA — rose-500 (landing badge, section labels, hovers)
  static const Color accentRose = Color(0xFFF43F5E);
  /// Primary CTA hover / emphasis — rose-600
  static const Color accentRoseDark = Color(0xFFE11D48);
  /// Secondary / links — violet-500 (landing gradient accent)
  static const Color accentViolet = Color(0xFF8B5CF6);

  /// Legacy names (map to new palette for compatibility)
  static const Color accentPurple = Color(0xFF8B5CF6);       // same as accentViolet
  static const Color accentGradientStart = Color(0xFF7C3AED); // violet-600
  static const Color accentGradientEnd = Color(0xFFEC4899);  // pink-500
  static const Color accentPink = Color(0xFFEC4899);         // pink-500

  /// Success / online — green (unchanged)
  static const Color onlineGreen = Color(0xFF2ECC71);
  /// Error / notification — rose-500 for consistency
  static const Color notificationRed = Color(0xFFF43F5E);
  /// Warning — amber (slightly softer than before)
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color accentYellow = Color(0xFFF59E0B);
  static const Color accentRed = notificationRed;

  /// Semantic aliases (used by buttons, inputs, feedback)
  static const Color primaryLight = Color(0xFFF43F5E);   // accentRose
  static const Color secondaryLight = Color(0xFF8B5CF6); // accentViolet
  static const Color feedbackSuccess = Color(0xFF2ECC71); // onlineGreen
  static const Color feedbackError = Color(0xFFE11D48);   // rose-600 for errors

  // ─── Optional tint backgrounds (landing hero: rose-50, violet-50) ──────────
  /// Soft rose background for highlights (landing rose-50)
  static const Color tintRoseLight = Color(0xFFFFF1F2);
  /// Soft violet background (landing violet-50)
  static const Color tintVioletLight = Color(0xFFF5F3FF);
  /// Dark mode: subtle rose tint for cards
  static const Color tintRoseDark = Color(0xFF3F1F24);
  static const Color tintVioletDark = Color(0xFF2E2640);

  // ─── LGBT / Pride gradient (matches landing Logo.tsx) ───────────────────────
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

  /// Primary brand gradient (rose → violet, for buttons/headers)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFF8B5CF6)],
    stops: [0.0, 1.0],
  );
}
