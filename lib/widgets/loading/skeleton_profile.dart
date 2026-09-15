import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/premium/premium_layout.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for profile page (hero + gallery + section cards).
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  static const double _sectionGap = AppSpacing.spacingXL;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.sizeOf(context).width;
    final photoSize = (screenW * 0.28).clamp(104.0, 132.0);
    final nameH = AppTypography.h2.fontSize ?? 18;
    final metaH = AppTypography.body.fontSize ?? 14;
    final titleH = AppTypography.bodyLarge.fontSize ?? 16;
    final chipH = AppTypography.labelMedium.fontSize ?? 14;
    final actionH = AppSpacing.spacingXXL + AppSpacing.spacingMD;
    final shellColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return ResponsiveGrid.constrained(
      context,
      CustomScrollView(
        physics: AppScroll.bouncing,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.spacingLG,
                    AppSpacing.spacingXS,
                    AppSpacing.spacingLG,
                    0,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: shellColor,
                      borderRadius: BorderRadius.circular(AppRadius.radiusXL),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.spacingLG,
                        AppSpacing.spacingMD,
                        AppSpacing.spacingLG,
                        AppSpacing.spacingMD,
                      ),
                      child: Column(
                        children: [
                          SkeletonLoader(
                            width: photoSize,
                            height: photoSize,
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusLG,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingMD),
                          SkeletonLoader(
                            width: 180,
                            height: nameH,
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusSM,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingSM),
                          SkeletonLoader(
                            width: 120,
                            height: metaH,
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusSM,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingMD),
                          Row(
                            children: List.generate(
                              3,
                              (_) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingXS,
                                  ),
                                  child: SkeletonLoader(
                                    height: actionH,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.radiusRound,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacingMD),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(
                              3,
                              (_) => Column(
                                children: [
                                  SkeletonLoader(
                                    width: 40,
                                    height: 40,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.radiusRound,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.spacingSM),
                                  SkeletonLoader(
                                    width: 36,
                                    height: metaH,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.radiusSM,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _sectionGap),
                _SectionCard(
                  color: shellColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 90,
                        height: titleH,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      const SizedBox(height: AppSpacing.spacingMD),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 0.82,
                        mainAxisSpacing: AppSpacing.spacingSM,
                        crossAxisSpacing: AppSpacing.spacingSM,
                        children: List.generate(
                          3,
                          (_) => SkeletonLoader(
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusMD,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _sectionGap),
                _SectionCard(
                  color: shellColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 60,
                        height: titleH,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      const SizedBox(height: AppSpacing.spacingMD),
                      SkeletonLoader(
                        width: double.infinity,
                        height: metaH,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      const SizedBox(height: AppSpacing.spacingSM),
                      SkeletonLoader(
                        width: double.infinity,
                        height: metaH,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _sectionGap),
                _SectionCard(
                  color: shellColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: 100,
                        height: titleH,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      const SizedBox(height: AppSpacing.spacingMD),
                      Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: AppSpacing.spacingSM,
                        children: List.generate(
                          6,
                          (_) => SkeletonLoader(
                            width: 80,
                            height: chipH + AppSpacing.spacingMD,
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusRound,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXXL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: child,
    );
  }
}
