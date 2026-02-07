// Animation durations and curves — minimal, app-wide
// Use these everywhere for consistent tap/transition timing.

import 'package:flutter/material.dart';

/// Centralized animation durations and curves.
/// Use for taps, page transitions, modals, list stagger, and feedback.
class AppAnimations {
  AppAnimations._();

  // --- Durations (ms) ---

  /// Button / icon press feedback. 120–150 ms.
  static const Duration tapDuration = Duration(milliseconds: 130);

  /// Push / pop page transitions. ~300 ms.
  static const Duration transitionPage = Duration(milliseconds: 300);

  /// Bottom sheet, dialog open/close. ~250 ms.
  static const Duration transitionModal = Duration(milliseconds: 250);

  /// Delay between list items on staggered appear. 40–60 ms per item.
  static const Duration listItemStagger = Duration(milliseconds: 50);

  /// Snackbar, validation, small feedback. 150–200 ms.
  static const Duration feedbackShort = Duration(milliseconds: 180);

  /// Discovery card exit when advancing to next. ~200 ms.
  static const Duration cardExit = Duration(milliseconds: 200);

  /// List item appear (fade + slide) for stagger. ~200 ms.
  static const Duration listItemAppear = Duration(milliseconds: 200);

  /// Shimmer / skeleton loop. ~1–1.5 s, low contrast.
  static const Duration shimmerDuration = Duration(milliseconds: 1400);

  /// Snackbar / toast enter and exit. ~200 ms.
  static const Duration snackbarTransition = Duration(milliseconds: 200);

  // --- Curves ---

  /// Most transitions (push, modal, button release).
  static const Curve curveDefault = Curves.easeOutCubic;

  /// Where a bit more motion is acceptable (e.g. dialog scale-in).
  static const Curve curveEmphasized = Curves.easeInOutCubic;

  // --- Scale ---

  /// Scale factor on button/icon press (1 → this value).
  static const double buttonPressScale = 0.97;

  /// Optional: respect reduce-motion. Pass from build(context).
  static bool animationsEnabled(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }

  /// Returns [tapDuration] if animations are enabled, otherwise [Duration.zero].
  static Duration effectiveTapDuration(BuildContext context) {
    return animationsEnabled(context) ? tapDuration : Duration.zero;
  }
}
