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
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Image skeleton
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.radiusXL),
                      topRight: Radius.circular(AppRadius.radiusXL),
                    ),
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
          // Loading text
          Text(
            'Finding your perfect matches...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

