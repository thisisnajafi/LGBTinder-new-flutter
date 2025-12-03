// Widget: ListTileCustom
// Custom list tile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';

/// Custom list tile widget
/// Enhanced list tile with better styling and customization
class ListTileCustom extends ConsumerWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool dense;
  final Color? tileColor;
  final Color? selectedTileColor;

  const ListTileCustom({
    Key? key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.dense = false,
    this.tileColor,
    this.selectedTileColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = tileColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingLG,
          vertical: dense ? AppSpacing.spacingSM : AppSpacing.spacingMD,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: AppSpacing.spacingMD),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: AppTypography.body.copyWith(
                        color: enabled ? textColor : secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (subtitle != null) ...[
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      subtitle!,
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: AppSpacing.spacingMD),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
