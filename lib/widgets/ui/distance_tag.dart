// Widget: DistanceTag
// Distance display tag
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Distance tag widget
/// Displays distance with location icon
class DistanceTag extends ConsumerWidget {
  final double distance; // in kilometers
  final String? unit; // "km" or "mi"

  const DistanceTag({
    Key? key,
    required this.distance,
    this.unit,
  }) : super(key: key);

  String _formatDistance() {
    final unitValue = unit ?? 'km';
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)}$unitValue';
    } else {
      return '${distance.toStringAsFixed(0)}$unitValue';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingMD,
        vertical: AppSpacing.spacingSM,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: AppColors.accentPurple,
          ),
          SizedBox(width: AppSpacing.spacingXS),
          Text(
            _formatDistance(),
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
