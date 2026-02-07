import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for discovery page
class SkeletonDiscovery extends StatelessWidget {
  const SkeletonDiscovery({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Dark: use clearly visible gray + border so card stands out on black background
    final cardColor = isDark
        ? const Color(0xFF252528)
        : AppColors.backgroundLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Card skeleton
          Container(
            width: 300,
            height: 500,
            margin: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusXL),
              border: isDark
                  ? Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Image skeleton with soft pride shimmer (discovery only); stronger in dark mode so visible
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.radiusXL),
                      topRight: Radius.circular(AppRadius.radiusXL),
                    ),
                    highlightColorOverride: isDark
                        ? Colors.white.withOpacity(0.22)
                        : AppColors.lgbtGradient[4].withOpacity(0.12),
                  ),
                ),
                // Info skeleton
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 150,
                        height: 20,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      SizedBox(height: AppSpacing.spacingSM),
                      SkeletonLoader(
                        width: 100,
                        height: 16,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      SizedBox(height: AppSpacing.spacingMD),
                      SkeletonLoader(
                        width: double.infinity,
                        height: 14,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      SizedBox(height: AppSpacing.spacingSM),
                      SkeletonLoader(
                        width: 200,
                        height: 14,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingXL),
          // Loading text — explicit color so visible in dark mode
          Text(
            'Finding your perfect matches...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

