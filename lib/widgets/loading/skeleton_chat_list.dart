import 'package:flutter/material.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'skeleton_loader.dart';

/// Skeleton loader for chat list page
class SkeletonChatList extends StatelessWidget {
  const SkeletonChatList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid.constrained(
      context,
      ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              SkeletonLoader(
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonLoader(
                            height: 16,
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusSM),
                          ),
                        ),
                        SizedBox(width: AppSpacing.spacingSM),
                        SkeletonLoader(
                          width: 50,
                          height: 12,
                          borderRadius:
                              BorderRadius.circular(AppRadius.radiusSM),
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
      ),
    );
  }
}

