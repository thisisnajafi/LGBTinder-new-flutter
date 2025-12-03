// Widget: LastSeenWidget
// Last seen timestamp widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';

/// Last seen timestamp widget
/// Displays when a user was last seen online
class LastSeenWidget extends ConsumerWidget {
  final DateTime? lastSeenAt;
  final bool isOnline;

  const LastSeenWidget({
    Key? key,
    this.lastSeenAt,
    this.isOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (isOnline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.onlineGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.spacingXS),
          Text(
            'Online',
            style: AppTypography.caption.copyWith(color: textColor),
          ),
        ],
      );
    }

    if (lastSeenAt == null) {
      return Text(
        'Offline',
        style: AppTypography.caption.copyWith(color: textColor),
      );
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt!);

    String text;
    if (difference.inMinutes < 1) {
      text = 'Just now';
    } else if (difference.inMinutes < 60) {
      text = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      text = '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      text = '${difference.inDays}d ago';
    } else {
      text = 'Last seen ${lastSeenAt!.day}/${lastSeenAt!.month}';
    }

    return Text(
      'Last seen $text',
      style: AppTypography.caption.copyWith(color: textColor),
    );
  }
}
