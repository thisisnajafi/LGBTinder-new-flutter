// Widget: AnimatedSnackbar
// Animated snackbar notifications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Animated snackbar widget
/// Custom snackbar with slide-in animation and gradient background
class AnimatedSnackbar extends ConsumerWidget {
  final String message;
  final SnackbarType type;
  final Duration duration;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AnimatedSnackbar({
    Key? key,
    required this.message,
    this.type = SnackbarType.info,
    this.duration = const Duration(seconds: 3),
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AnimatedSnackbar(
          message: message,
          type: type,
          duration: duration,
          onAction: onAction,
          actionLabel: actionLabel,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(AppSpacing.spacingLG),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = Colors.white;

    Color getBackgroundColor() {
      switch (type) {
        case SnackbarType.success:
          return AppColors.onlineGreen;
        case SnackbarType.error:
          return AppColors.notificationRed;
        case SnackbarType.warning:
          return AppColors.warningYellow;
        case SnackbarType.info:
        default:
          return AppColors.accentPurple;
      }
    }

    IconData getIcon() {
      switch (type) {
        case SnackbarType.success:
          return Icons.check_circle;
        case SnackbarType.error:
          return Icons.error;
        case SnackbarType.warning:
          return Icons.warning;
        case SnackbarType.info:
        default:
          return Icons.info;
      }
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        gradient: type == SnackbarType.info
            ? AppTheme.accentGradient
            : LinearGradient(
                colors: [
                  getBackgroundColor(),
                  getBackgroundColor().withOpacity(0.8),
                ],
              ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            getIcon(),
            color: textColor,
            size: 24,
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: textColor),
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(width: AppSpacing.spacingMD),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.button.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum SnackbarType {
  success,
  error,
  warning,
  info,
}
