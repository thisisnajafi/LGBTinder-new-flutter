// Widget: EmptyState
// Empty state widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../buttons/gradient_button.dart';
import '../../core/utils/app_icons.dart';

/// Empty state widget
/// Displays a message when there's no content to show
class EmptyState extends ConsumerWidget {
  final String title;
  final String? message;
  final IconData? icon; // Legacy support
  final String? iconPath; // SVG icon path
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    Key? key,
    required this.title,
    this.message,
    this.icon,
    this.iconPath,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null || icon != null) ...[
              iconPath != null
                  ? AppSvgIcon(
                      assetPath: iconPath!,
                      size: 64,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                    )
                  : Icon(
                      icon!,
                      size: 64,
                      color: secondaryTextColor.withValues(alpha: 0.5),
                    ),
              SizedBox(height: AppSpacing.spacingXL),
            ],
            Text(
              title,
              style: AppTypography.h3.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: AppSpacing.spacingMD),
              Text(
                message!,
                style: AppTypography.body.copyWith(color: secondaryTextColor),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppSpacing.spacingXXL),
              GradientButton(
                text: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
