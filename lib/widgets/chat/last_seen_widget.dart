// Widget: LastSeenWidget
// Last seen timestamp widget
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../features/chat/utils/chat_presence_copy.dart';

/// Last seen timestamp widget
/// Displays when a user was last seen online, or "is typing"
class LastSeenWidget extends StatelessWidget {
  final DateTime? lastSeenAt;
  final bool isOnline;
  final bool isTyping;

  const LastSeenWidget({
    super.key,
    this.lastSeenAt,
    this.isOnline = false,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (isTyping) {
      return AppText(
        ChatPresenceCopy.isTyping,
        key: const ValueKey('peer-status-typing'),
        style: AppTypography.caption.copyWith(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
      );
    }

    if (isOnline) {
      return Row(
        key: const ValueKey('peer-status-online'),
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
        key: const ValueKey('peer-status-offline'),
        style: AppTypography.caption.copyWith(color: textColor),
        maxLines: 1,
      );
    }

    return AppText(
      ChatPresenceCopy.lastSeenLabel(lastSeen),
      key: const ValueKey('peer-status-last-seen'),
      style: AppTypography.caption.copyWith(color: textColor),
      maxLines: 1,
    );
  }
}
