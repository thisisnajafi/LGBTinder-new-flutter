import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import 'skeleton_loader.dart';

/// Shimmer skeleton for the subscription / choose plan screen.
class SkeletonSubscriptionPlans extends StatelessWidget {
  const SkeletonSubscriptionPlans({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark
        ? AppColors.borderMediumDark
        : AppColors.borderMediumLight;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.spacingLG,
              AppSpacing.spacingLG,
              AppSpacing.spacingLG,
              AppSpacing.spacingSM,
            ),
            children: [
              SkeletonLoader(
                width: 220,
                height: 28,
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              SizedBox(height: AppSpacing.spacingSM),
              SkeletonLoader(
                width: double.infinity,
                height: 16,
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              SizedBox(height: AppSpacing.spacingXS),
              SkeletonLoader(
                width: 260,
                height: 16,
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              SizedBox(height: AppSpacing.spacingXL),
              SkeletonLoader(
                width: double.infinity,
                height: 44,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              SizedBox(height: AppSpacing.spacingXL),
              for (var i = 0; i < 3; i++) ...[
                _PlanCardSkeleton(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  durationRows: i == 0 ? 3 : 2,
                ),
                SizedBox(height: AppSpacing.spacingLG),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.spacingLG,
            AppSpacing.spacingMD,
            AppSpacing.spacingLG,
            AppSpacing.spacingLG,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonLoader(
                width: 180,
                height: 14,
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              SkeletonLoader(
                width: double.infinity,
                height: 52,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCardSkeleton extends StatelessWidget {
  final Color surfaceColor;
  final Color borderColor;
  final int durationRows;

  const _PlanCardSkeleton({
    required this.surfaceColor,
    required this.borderColor,
    required this.durationRows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(
                width: 4,
                height: 48,
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 120,
                      height: 20,
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusSM),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    SkeletonLoader(
                      width: 200,
                      height: 14,
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusSM),
                    ),
                  ],
                ),
              ),
              SkeletonLoader(
                width: 22,
                height: 22,
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          SkeletonLoader(
            width: 140,
            height: 16,
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          for (var i = 0; i < durationRows; i++) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              margin: EdgeInsets.only(bottom: AppSpacing.spacingSM),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: borderColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(
                          width: 80,
                          height: 16,
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusSM),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        SkeletonLoader(
                          width: 120,
                          height: 12,
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusSM),
                        ),
                      ],
                    ),
                  ),
                  SkeletonLoader(
                    width: 56,
                    height: 22,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppSpacing.spacingSM),
          SkeletonLoader(
            width: 110,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          ),
        ],
      ),
    );
  }
}
