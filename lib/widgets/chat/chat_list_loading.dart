// Widget: ChatListLoading
// Loading state for chat list
import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_list_view.dart';
import '../loading/skeleton_loader.dart';

/// Loading state for chat list widget
/// Shows skeleton loaders while chat list is loading
class ChatListLoading extends StatelessWidget {
  static const double _avatarSize = 52;

  final int itemCount;

  const ChatListLoading({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final nameHeight = AppTypography.body.fontSize!;
    final previewHeight = AppTypography.bodySmall.fontSize!;
    final timeHeight = AppTypography.labelSmall.fontSize!;

    return ResponsiveGrid.constrained(
      context,
      AppListView.separated(
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.spacingXS),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingSM,
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  width: _avatarSize,
                  height: _avatarSize,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: double.infinity,
                        height: nameHeight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: AppSpacing.spacingXS),
                      SkeletonLoader(
                        width: 150,
                        height: previewHeight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingSM),
                SkeletonLoader(
                  width: 40,
                  height: timeHeight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
