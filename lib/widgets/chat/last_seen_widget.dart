// Widget: LastSeenWidget
// Last seen timestamp widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../features/chat/utils/chat_presence_copy.dart';

/// Last seen timestamp widget
/// Displays when a user was last seen online
class LastSeenWidget extends ConsumerWidget {
  final DateTime? lastSeenAt;
  final bool isOnline;

  const LastSeenWidget({
    super.key,
    this.lastSeenAt,
    this.isOnline = false,
  });

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
          AppText(
            ChatPresenceCopy.online,
            style: AppTypography.caption.copyWith(color: textColor),
            maxLines: 1,
          ),
        ],
      );
    }

    final lastSeen = lastSeenAt?.toLocal();
    if (lastSeen == null) {
      return AppText(
        ChatPresenceCopy.offline,
        style: AppTypography.caption.copyWith(color: textColor),
        maxLines: 1,
      );
    }

    return AppText(
      ChatPresenceCopy.lastSeenLabel(lastSeen),
      style: AppTypography.caption.copyWith(color: textColor),
      maxLines: 1,
    );
  }
}
