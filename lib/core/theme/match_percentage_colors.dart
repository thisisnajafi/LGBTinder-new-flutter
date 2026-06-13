import 'package:flutter/material.dart';

/// Colors for discovery match percentage bands (0–9%, 10–19%, …, 90–100%).
abstract final class MatchPercentageColors {
  /// Ten distinct colors from low to high compatibility.
  static const List<Color> _bandColors = [
    Color(0xFFEF4444), // 0–9%
    Color(0xFFF97316), // 10–19%
    Color(0xFFFB923C), // 20–29%
    Color(0xFFFBBF24), // 30–39%
    Color(0xFFEAB308), // 40–49%
    Color(0xFF84CC16), // 50–59%
    Color(0xFF22C55E), // 60–69%
    Color(0xFF14B8A6), // 70–79%
    Color(0xFF3B82F6), // 80–89%
    Color(0xFF8B5CF6), // 90–100%
  ];

  /// Returns the color for [percentage] using 10-point bands.
  static Color colorFor(int percentage) {
    final clamped = percentage.clamp(0, 100);
    final bucket = (clamped ~/ 10).clamp(0, _bandColors.length - 1);
    return _bandColors[bucket];
  }
}
