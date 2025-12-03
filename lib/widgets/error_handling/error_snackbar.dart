// Widget: ErrorSnackbar
// Error snackbar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../match_interaction/animated_snackbar.dart';

/// Error snackbar widget
/// Displays error messages as snackbars
class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    AnimatedSnackbar.show(
      context,
      message: message,
      type: SnackbarType.error,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }
}
