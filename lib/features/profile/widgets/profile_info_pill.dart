import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

/// Icon + label pill for profile metadata.
class ProfileInfoPill extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool highlighted;

  const ProfileInfoPill({
    super.key,
    required this.iconPath,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = highlighted
        ? AppColors.accentPurple.withValues(alpha: 0.15)
        : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight);
    final border = highlighted
        ? AppColors.accentPurple.withValues(alpha: 0.4)
        : (isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingMD,
        vertical: AppSpacing.spacingSM,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: iconPath,
            size: 16,
            color: highlighted ? AppColors.accentPurple : AppColors.accentRose,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Flexible(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: highlighted
                    ? AppColors.accentPurple
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
