import 'package:flutter/material.dart';

import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/widgets/app_page_header.dart';
import 'skeleton_loader.dart';

/// Skeleton loader matching [NotificationTile] layout (icon circle + text lines).
class SkeletonNotifications extends StatelessWidget {
  const SkeletonNotifications({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppPageHeader.horizontalPadding,
        0,
        AppPageHeader.horizontalPadding,
        AppSpacing.spacingLG,
      ),
      itemCount: itemCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
            child: SkeletonLoader(
              width: 56,
              height: 12,
              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.spacingXS),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 48,
                  height: 48,
                  borderRadius:
                      BorderRadius.circular(AppRadius.radiusRound),
                ),
                const SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SkeletonLoader(
                              width: double.infinity,
                              height: 16,
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusSM,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacingSM),
                          SkeletonLoader(
                            width: 48,
                            height: 12,
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusSM,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacingSM),
                      SkeletonLoader(
                        width: double.infinity,
                        height: 14,
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      const SizedBox(height: AppSpacing.spacingXS),
                      SkeletonLoader(
                        width: 180,
                        height: 14,
                        borderRadius:
                            BorderRadius.circular(AppRadius.radiusSM),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
