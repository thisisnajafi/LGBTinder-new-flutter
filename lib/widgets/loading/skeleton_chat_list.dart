import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for chat list page
class SkeletonChatList extends StatelessWidget {
  const SkeletonChatList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        child: Row(
          children: [
            // Avatar skeleton
            SkeletonLoader(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            ),
            SizedBox(width: AppSpacing.spacingMD),
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonLoader(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      SkeletonLoader(
                        width: 50,
                        height: 12,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                    ],
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
          ],
        ),
      ),
    );
  }
}

