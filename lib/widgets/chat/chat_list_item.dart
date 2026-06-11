// Widget: ChatListItem — REF-04 conversation row
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_header.dart';
import '../../core/widgets/profile_image_widget.dart';
import '../../shared/models/user_tier.dart';
import '../../shared/providers/user_tier_provider.dart';
import '../../features/chat/utils/chat_message_preview.dart';
import 'typing_indicator.dart';

/// Single conversation row in the messenger list.
class ChatListItem extends ConsumerWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final bool isMuted;
  final VoidCallback? onTap;

  const ChatListItem({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    this.isMuted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tier = ref.watch(userTierProvider);
    final isLocked = tier == UserTier.basid;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final displayName = name.trim().isNotEmpty ? name.trim() : 'User';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPageHeader.horizontalPadding,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: ProfileImageWidget(
                        imageUrl: avatarUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.onlineGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacingXS),
                      _MessagePreview(
                        isTyping: isTyping,
                        lastMessage: lastMessage,
                        lastMessageType: lastMessageType,
                        isLocked: isLocked,
                        mutedColor: mutedColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingSM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (lastMessageTime != null)
                      Text(
                        _formatTime(lastMessageTime!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    if (unreadCount > 0) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${time.day}/${time.month}';
  }
}

class _MessagePreview extends StatelessWidget {
  final bool isTyping;
  final String? lastMessage;
  final String? lastMessageType;
  final bool isLocked;
  final Color mutedColor;

  const _MessagePreview({
    required this.isTyping,
    required this.lastMessage,
    this.lastMessageType,
    required this.isLocked,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isTyping) {
      return const TypingIndicator();
    }

    final previewText = lastMessage ?? 'No messages yet';
    final textStyle = theme.textTheme.bodySmall?.copyWith(color: mutedColor);
    final isVoice = isVoiceMessagePreview(lastMessageType);

    Widget previewContent = isVoice
        ? Row(
            children: [
              AppSvgIcon(
                assetPath: AppIcons.microphone,
                size: 14,
                color: mutedColor,
              ),
              const SizedBox(width: AppSpacing.spacingXS),
              Expanded(
                child: Text(
                  previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          )
        : Text(
            previewText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          );

    if (!isLocked) {
      return previewContent;
    }

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: previewContent,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: AppSvgIcon(
            assetPath: AppIcons.lock,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
