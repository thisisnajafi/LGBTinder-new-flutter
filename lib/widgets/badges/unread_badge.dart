// Widget: UnreadBadge
// Unread message badge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';

/// Unread message badge widget
/// Displays unread message count in chat list items
class UnreadBadge extends ConsumerWidget {
  final int count;
  final double? size;

  const UnreadBadge({
    Key? key,
    required this.count,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final badgeSize = size ?? 20.0;
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      width: badgeSize,
      height: badgeSize,
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      decoration: BoxDecoration(
        color: AppColors.notificationRed,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          displayCount,
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontSize: count > 99 ? 8 : 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
