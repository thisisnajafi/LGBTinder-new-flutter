// Widget: ChatListItem — REF-04 conversation row
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_date_time.dart';
import '../../core/cache/peer_avatar_cache.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/media_url.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../core/widgets/profile_image_widget.dart';
import '../../features/chat/providers/conversation_mute_cache_provider.dart';
import '../../features/chat/providers/conversation_pin_cache_provider.dart';
import '../../features/chat/providers/user_presence_cache_provider.dart';
import '../../features/chat/providers/chat_thread_providers.dart';
import '../../features/chat/utils/chat_message_preview.dart';
import '../../features/chat/utils/chat_presence_copy.dart';
import 'typing_indicator.dart';
import 'message_status_indicator.dart';
import 'chat_search_highlight_text.dart';
import 'chat_unread_badge.dart';
import 'chat_online_dot.dart';
import '../../features/chat/data/models/message_delivery_status.dart';
import '../../core/responsive/responsive.dart';

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
  final bool isPinned;
  final bool lastMessageFromMe;
  final bool lastMessageIsRead;
  final bool lastMessageIsDelivered;
  final DateTime? lastSeenAt;
  final String highlightQuery;
  final bool hasPlan;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const pinIconKey = ValueKey('chat-list-pin-icon');
  static const previewLockKey = ValueKey('chat-list-preview-lock');

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
    this.isPinned = false,
    this.lastMessageFromMe = false,
    this.lastMessageIsRead = false,
    this.lastMessageIsDelivered = false,
    this.lastSeenAt,
    this.highlightQuery = '',
    required this.hasPlan,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLocked = !hasPlan;
    final cacheMuted = ref.watch(
      conversationMuteCacheProvider.select((ids) => ids.contains(userId)),
    );
    final muted = cacheMuted || isMuted;
    final cachePinned = ref.watch(
      conversationPinCacheProvider.select((ids) => ids.contains(userId)),
    );
    final pinned = cachePinned || isPinned;
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final displayName = name.trim().isNotEmpty ? name.trim() : 'User';
    final cachedAvatar = ref.watch(
      peerAvatarCacheProvider.select((avatars) => avatars[userId]),
    );
    final resolvedAvatar = MediaUrl.pick(
      userId: userId,
      incoming: avatarUrl,
      cached: cachedAvatar,
    );
    final presence = ref.watch(
      userPresenceCacheProvider.select((map) => map[userId]),
    );
    final liveOnline = presence?.isOnline ?? isOnline;
    final seenAt = presence?.lastSeenAt ?? lastSeenAt;
    final liveTyping = ref.watch(
      chatTypingUsersProvider.select((m) => m[userId] == true),
    );
    final typing = liveTyping || isTyping;

    return PremiumTapScale(
      onTap: onTap ?? () {},
      onLongPress: onLongPress,
      semanticLabel: 'Chat with $displayName',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(
            color: unreadCount > 0
                ? AppColors.accentPink.withValues(alpha: 0.25)
                : AppColors.accentViolet.withValues(alpha: isDark ? 0.1 : 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: ProfileImageWidget(
                        imageUrl: resolvedAvatar,
                        userId: userId,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (liveOnline)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: ChatOnlineDot(
                          ringColor: isDark
                              ? AppColors.cardBackgroundDark
                              : AppColors.cardBackgroundLight,
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
                      Row(
                        children: [
                          Expanded(
                            child: ChatSearchHighlightText(
                              text: displayName,
                              query: highlightQuery,
                              maxLines: 1,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (pinned)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: AppSvgIcon(
                                key: ChatListItem.pinIconKey,
                                assetPath: AppIcons.bookmark,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          if (muted)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: AppSvgIcon(
                                assetPath: AppIcons.bellSlash,
                                size: 14,
                                color: mutedColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacingXS),
                      _MessagePreview(
                        isTyping: typing,
                        lastMessage: lastMessage,
                        lastMessageType: lastMessageType,
                        isOnline: liveOnline,
                        lastSeenAt: seenAt,
                        isLocked: isLocked,
                        mutedColor: mutedColor,
                        highlightQuery: highlightQuery,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lastMessageFromMe && unreadCount == 0) ...[
                            MessageStatusIndicator(
                              isRead: lastMessageIsRead,
                              isDelivered: lastMessageIsDelivered,
                              deliveryStatus: MessageDeliveryStatus.sent,
                              messageId: 1,
                              sentColor: mutedColor,
                              readColor: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          AppText(
                            _formatTime(lastMessageTime!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: mutedColor,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    if (unreadCount > 0) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      ChatUnreadBadge(count: unreadCount),
                    ],
                  ],
                ),
              ],
            ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = AppDateTime.toLocal(time);
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inDays == 0) {
      return AppDateTime.formatChatTime(local);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${local.day}/${local.month}';
  }
}

class _MessagePreview extends StatelessWidget {
  final bool isTyping;
  final String? lastMessage;
  final String? lastMessageType;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final bool isLocked;
  final Color mutedColor;
  final String highlightQuery;

  const _MessagePreview({
    required this.isTyping,
    required this.lastMessage,
    this.lastMessageType,
    required this.isOnline,
    this.lastSeenAt,
    required this.isLocked,
    required this.mutedColor,
    this.highlightQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isTyping) {
      return const TypingIndicator();
    }

    final previewText = ChatPresenceCopy.hasLastMessage(lastMessage)
        ? lastMessage!.trim()
        : ChatPresenceCopy.emptyPreview(
            isOnline: isOnline,
            lastSeenAt: lastSeenAt,
          );
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
                child: ChatSearchHighlightText(
                  text: previewText,
                  query: highlightQuery,
                  maxLines: 1,
                  style: textStyle,
                ),
              ),
            ],
          )
        : ChatSearchHighlightText(
            text: previewText,
            query: highlightQuery,
            maxLines: 1,
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
            key: ChatListItem.previewLockKey,
            assetPath: AppIcons.lock,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
