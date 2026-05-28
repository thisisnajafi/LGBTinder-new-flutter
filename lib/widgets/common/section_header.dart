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
  /// When null, matches section title color (same as list row icons in settings).
  final Color? iconColor;
  /// Extra space above the section title (e.g. after a group of cards).
  final double topSpacing;
  /// Use when the parent [ListView] already applies horizontal padding.
  final bool compactLayout;

  const SectionHeader({
    Key? key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.iconPath,
    this.iconColor,
    this.topSpacing = 0,
    this.compactLayout = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final resolvedIconColor = iconColor ?? textColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compactLayout ? 0 : AppSpacing.spacingLG,
        topSpacing,
        compactLayout ? 0 : AppSpacing.spacingLG,
        AppSpacing.spacingMD,
      ),
      child: Row(
        children: [
          if (iconPath != null || icon != null) ...[
            iconPath != null
                ? AppSvgIcon(
                    assetPath: iconPath!,
                    size: 24,
                    color: resolvedIconColor,
                  )
                : Icon(
                    icon!,
                    color: resolvedIconColor,
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
