import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lightweight haptic helpers for onboarding micro-interactions.
class AppHaptics {
  AppHaptics._();

  static void selection() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
}
