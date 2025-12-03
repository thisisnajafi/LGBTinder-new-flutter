// Widget: FilterChip
// Filter chip widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Filter chip widget
/// Custom filter chip with selection state
class FilterChip extends ConsumerWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;

  const FilterChip({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final selectedColorValue = selectedColor ?? AppColors.accentPurple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColorValue.withOpacity(0.2)
              : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          border: Border.all(
            color: isSelected ? selectedColorValue : borderColor,
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
                color: isSelected ? selectedColorValue : textColor,
              ),
              SizedBox(width: AppSpacing.spacingXS),
            ],
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: isSelected ? selectedColorValue : textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: AppSpacing.spacingXS),
              Icon(
                Icons.check_circle,
                size: 16,
                color: selectedColorValue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
