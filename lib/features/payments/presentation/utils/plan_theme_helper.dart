// Plan theme and feature list aligned with backend PlanSeeder (Basic, Premium, Golden)
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Theme and display data per plan name (Basic, Premium, Golden from PlanSeeder).
class PlanThemeData {
  final Color accent;
  final Color accentSoft;
  final LinearGradient? gradient;
  final List<String> features;
  final String tagline;
  final bool isPopular;

  const PlanThemeData({
    required this.accent,
    required this.accentSoft,
    this.gradient,
    required this.features,
    required this.tagline,
    this.isPopular = false,
  });
}

/// Returns theme and features for a plan by name. Matches backend PlanSeeder titles.
PlanThemeData getPlanTheme(String planName) {
  final name = planName.trim().toLowerCase();
  if (name.contains('premium')) {
    return PlanThemeData(
      accent: AppColors.accentViolet,
      accentSoft: AppColors.tintVioletLight,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      ),
      tagline: 'Enhanced features for better experience',
      isPopular: true,
      features: const [
        'Unlimited chat',
        'Advanced filters',
        'Direct chat',
        'Like menu',
        'Daily profile picks',
        '5 Superlikes per month',
      ],
    );
  }
  if (name.contains('golden') || name.contains('gold')) {
    return PlanThemeData(
      accent: const Color(0xFFD97706),
      accentSoft: const Color(0xFFFEF3C7),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
      ),
      tagline: 'Ultimate features for the best experience',
      isPopular: false,
      features: const [
        'Everything in Premium',
        'Voice & video calls',
        'AI match',
        '10 Superlikes per month',
      ],
    );
  }
  // Basic (default) — bronze/amber
  return PlanThemeData(
    accent: const Color(0xFFB45309),
    accentSoft: const Color(0xFFFFFBEB),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB45309), Color(0xFFD97706)],
    ),
    tagline: 'Essential features for getting started',
    isPopular: false,
    features: const [
      'Unlimited chat',
      'See who likes you',
      'Basic discovery',
    ],
  );
}
