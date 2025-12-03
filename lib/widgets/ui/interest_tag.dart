// Widget: InterestTag
// Interest tag with icon
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Interest tag widget
/// Displays an interest with optional icon
class InterestTag extends ConsumerWidget {
  final String interest;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;

  const InterestTag({
    Key? key,
    required this.interest,
    this.icon,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPurple.withOpacity(0.2)
              : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPurple
                : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.accentPurple
                    : textColor,
              ),
              SizedBox(width: AppSpacing.spacingXS),
            ],
            Text(
              interest,
              style: AppTypography.body.copyWith(
                color: isSelected
                    ? AppColors.accentPurple
                    : textColor,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
