import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for profile page
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header skeleton
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Row(
              children: [
                // Avatar skeleton
                SkeletonLoader(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                // Name and info skeleton
                Expanded(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats skeleton
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (index) => Expanded(
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
                    SizedBox(height: AppSpacing.spacingXS),
                    SkeletonLoader(
                      width: 50,
                      height: 12,
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    ),
                  ],
                ),
              )),
            ),
          ),
          // Bio skeleton
          Container(
            margin: EdgeInsets.all(AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                SkeletonLoader(
                  width: 200,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
              ],
            ),
          ),
          // Photo gallery skeleton
          Container(
            height: 200,
            margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 150,
                margin: EdgeInsets.only(right: AppSpacing.spacingMD),
                child: SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                ),
              ),
            ),
          ),
          // Info sections skeleton
          ...List.generate(3, (index) => Container(
            margin: EdgeInsets.all(AppSpacing.spacingLG),
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
                  children: List.generate(4, (i) => SkeletonLoader(
                    width: 80,
                    height: 32,
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  )),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

