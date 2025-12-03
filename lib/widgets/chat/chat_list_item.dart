// Widget: ChatListItem
// Individual chat list item
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../avatar/avatar_with_status.dart';
import '../badges/unread_badge.dart';
import 'typing_indicator.dart';
import 'last_seen_widget.dart';

/// Chat list item widget
/// Displays a single chat conversation in the chat list
/// Data structure based on API: /api/chat/users
class ChatListItem extends ConsumerWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final VoidCallback? onTap;

  const ChatListItem({
    Key? key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingLG,
          vertical: AppSpacing.spacingMD,
        ),
        child: Row(
          children: [
            AvatarWithStatus(
              imageUrl: avatarUrl,
              name: name,
              isOnline: isOnline,
              size: 56.0,
            ),
            SizedBox(width: AppSpacing.spacingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.h3.copyWith(color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageTime != null)
                        Text(
                          _formatTime(lastMessageTime!),
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  Row(
                    children: [
                      Expanded(
                        child: isTyping
                            ? TypingIndicator()
                            : Text(
                                lastMessage ?? 'No messages yet',
                                style: AppTypography.body.copyWith(
                                  color: secondaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (unreadCount > 0) ...[
                        SizedBox(width: AppSpacing.spacingSM),
                        UnreadBadge(count: unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
