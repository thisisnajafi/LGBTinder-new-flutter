// Widget: AlertDialogCustom
// Custom alert dialog
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../buttons/gradient_button.dart';
import '../../core/utils/app_icons.dart';
import 'app_dialog.dart';

/// Custom alert dialog widget
/// Styled alert dialog with title, message, and action button
class AlertDialogCustom extends ConsumerWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onButtonTap;
  final IconData? icon; // Legacy support
  final String? iconPath; // SVG icon path
  final Color? iconColor;

  const AlertDialogCustom({
    Key? key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onButtonTap,
    this.icon,
    this.iconPath,
    this.iconColor,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon, // Legacy support
    String? iconPath, // SVG icon path
    Color? iconColor,
  }) {
    return showAppDialog(
      context: context,
      builder: (context) => AlertDialogCustom(
        title: title,
        message: message,
        buttonText: buttonText,
        icon: icon,
        iconPath: iconPath,
        iconColor: iconColor,
        onButtonTap: () => Navigator.of(context).pop(),
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
    final iconColorValue = iconColor ?? AppColors.accentPurple;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingXL),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null || icon != null) ...[
              iconPath != null
                  ? AppSvgIcon(
                      assetPath: iconPath!,
                      size: 64,
                      color: iconColorValue,
                    )
                  : Icon(
                      icon!,
                      size: 64,
                      color: iconColorValue,
                    ),
              SizedBox(height: AppSpacing.spacingLG),
            ],
            Text(
              title,
              style: AppTypography.h2.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              message,
              style: AppTypography.body.copyWith(color: secondaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacingXXL),
            GradientButton(
              text: buttonText,
              onPressed: onButtonTap ?? () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
