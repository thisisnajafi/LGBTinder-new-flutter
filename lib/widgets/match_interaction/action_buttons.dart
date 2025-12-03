// Widget: ActionButtons
// Swipe action buttons
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing_constants.dart';
import '../buttons/dislike_button.dart';
import '../buttons/superlike_button.dart';
import '../buttons/like_button.dart';

/// Action buttons widget
/// Container for like, superlike, and dislike buttons
class ActionButtons extends ConsumerWidget {
  final VoidCallback? onLike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onDislike;
  final bool isLiked;
  final bool isSuperliked;
  final bool isDisliked;

  const ActionButtons({
    Key? key,
    this.onLike,
    this.onSuperlike,
    this.onDislike,
    this.isLiked = false,
    this.isSuperliked = false,
    this.isDisliked = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingXL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          DislikeButton(
            onTap: onDislike,
            isActive: isDisliked,
            size: 56.0,
          ),
          SuperlikeButton(
            onTap: onSuperlike,
            isActive: isSuperliked,
            size: 64.0,
          ),
          LikeButton(
            onTap: onLike,
            isActive: isLiked,
            size: 72.0,
          ),
        ],
      ),
    );
  }
}
