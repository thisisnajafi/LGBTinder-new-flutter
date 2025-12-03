// Widget: SectionHeader
// Section header widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';

/// Section header widget
/// Displays a section title with optional action button
class SectionHeader extends ConsumerWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon; // Legacy support
  final String? iconPath; // SVG icon path

  const SectionHeader({
    Key? key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.iconPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      child: Row(
        children: [
          if (iconPath != null || icon != null) ...[
            iconPath != null
                ? AppSvgIcon(
                    assetPath: iconPath!,
                    size: 24,
                    color: AppColors.accentPurple,
                  )
                : Icon(
                    icon!,
                    color: AppColors.accentPurple,
                    size: 24,
                  ),
            SizedBox(width: AppSpacing.spacingSM),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.h2.copyWith(color: textColor),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.button.copyWith(
                  color: AppColors.accentPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
