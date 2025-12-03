import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for chat page
class SkeletonChat extends StatelessWidget {
  const SkeletonChat({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isSent = index % 2 == 0;
        return Container(
          margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
          child: Row(
            mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSent) ...[
                SkeletonLoader(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
                SizedBox(width: AppSpacing.spacingSM),
              ],
              Flexible(
                child: SkeletonLoader(
                  width: 200,
                  height: 50,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                ),
              ),
              if (isSent) ...[
                SizedBox(width: AppSpacing.spacingSM),
                SkeletonLoader(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

