import 'package:flutter/services.dart';

import '../providers/app_motion_prefs_provider.dart';

/// Lightweight haptic helpers. No-ops when the user disabled haptics
/// (PERF-SCR-HAPTIC-001).
class AppHaptics {
  AppHaptics._();

  static bool get enabled => AppMotionPreferences.hapticsEnabled;

  static void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  static void light() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  static void medium() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }
}
