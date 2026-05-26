import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for profile page (carousel + info sections layout).
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo carousel hero
          SkeletonLoader(
            width: double.infinity,
            height: 360,
            borderRadius: BorderRadius.zero,
          ),
          // Overlay name strip
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 180,
                  height: 24,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                SkeletonLoader(
                  width: 120,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Column(
                    children: [
                      SkeletonLoader(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                      SizedBox(height: AppSpacing.spacingSM),
                      SkeletonLoader(
                        width: 30,
                        height: 16,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          // Bio card
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 60,
                  height: 18,
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
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          // Info section chips
          ...List.generate(
            3,
            (_) => Container(
              margin: EdgeInsets.fromLTRB(
                AppSpacing.spacingLG,
                0,
                AppSpacing.spacingLG,
                AppSpacing.spacingLG,
              ),
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 100,
                    height: 18,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Wrap(
                    spacing: AppSpacing.spacingSM,
                    runSpacing: AppSpacing.spacingSM,
                    children: List.generate(
                      4,
                      (_) => SkeletonLoader(
                        width: 80,
                        height: 32,
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }
}
