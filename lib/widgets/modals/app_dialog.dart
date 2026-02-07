// App-level dialog helper with consistent fade + scale transition.
// Use instead of showDialog for AlertDialogCustom, ConfirmationDialog, etc.

import 'package:flutter/material.dart';
import '../../core/constants/animation_constants.dart';

/// Shows a dialog with fade + slight scale (0.98 → 1) using [AppAnimations.transitionModal].
/// Respects [MediaQuery.disableAnimations].
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  final duration = AppAnimations.animationsEnabled(context)
      ? AppAnimations.transitionModal
      : Duration.zero;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: AppAnimations.curveEmphasized,
      );
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
      final scale = Tween<double>(begin: 0.98, end: 1.0).animate(curve);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}
