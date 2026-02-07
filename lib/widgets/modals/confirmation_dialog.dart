// Widget: ConfirmationDialog
// Confirmation dialog
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../buttons/gradient_button.dart';
import 'app_dialog.dart';

/// Confirmation dialog widget
/// Custom styled confirmation dialog with title, message, and action buttons
class ConfirmationDialog extends ConsumerWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showAppDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(AppSpacing.spacingXL),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h2.copyWith(color: textColor),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  message,
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                ),
                SizedBox(height: AppSpacing.spacingXXL),
                Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelText,
                    style: AppTypography.button.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                GradientButton(
                  text: confirmText,
                  onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                  isFullWidth: false,
                  height: 40,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }
}
