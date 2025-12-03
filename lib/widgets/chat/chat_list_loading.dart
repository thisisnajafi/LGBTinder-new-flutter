// Widget: ChatListLoading
// Loading state for chat list
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing_constants.dart';
import '../loading/skeleton_loader.dart';
import '../avatar/avatar_with_status.dart';

/// Loading state for chat list widget
/// Shows skeleton loaders while chat list is loading
class ChatListLoading extends ConsumerWidget {
  final int itemCount;

  const ChatListLoading({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingLG,
            vertical: AppSpacing.spacingMD,
          ),
          child: Row(
            children: [
              SkeletonLoader(
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(999),
              ),
              SizedBox(width: AppSpacing.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    SkeletonLoader(
                      width: 150,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
