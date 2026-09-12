import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/utils/app_date_time.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/providers/chat_thread_providers.dart';
import '../../features/chat/utils/chat_bubble_group.dart';
import '../../features/chat/utils/chat_delivery_status_map.dart';
import '../../features/chat/utils/chat_reaction_summary.dart';
import '../../features/chat/utils/chat_reply_jump.dart';
import '../../features/chat/utils/chat_send_retry.dart';
import '../../features/chat/utils/chat_screenshot_ui.dart';
import 'chat_deleted_tombstone.dart';
import 'chat_system_message.dart';
import 'chat_message_enter_animation.dart';
import 'chat_reaction_chips.dart';
import 'chat_reply_highlight.dart';
import 'chat_swipe_to_reply.dart';
import 'message_bubble.dart';

/// Long-press on a bubble, with the press point for the floating menu.
typedef ChatMessageLongPressCallback = Future<void> Function(
  Map<String, dynamic> message, {
  Offset? at,
});

/// Single chat row with repaint isolation (PERF-PAGE-CHAT-004 / PERF-INFRA-011).
///
/// Watches [chatMessageProvider] for this row key so a neighbor edit/delivery
/// tick does not rebuild this bubble.
class ChatMessageListTile extends ConsumerStatefulWidget {
  final int peerUserId;
  final String rowKey;
  final void Function(Map<String, dynamic> message)? onRetry;
  final void Function(Map<String, dynamic> message)? onReply;
  final void Function(Map<String, dynamic> message)? onJumpToReply;
  final void Function(Map<String, dynamic> message, String emoji)? onReact;
  final ChatMessageLongPressCallback? onLongPress;
  final void Function(Map<String, dynamic> message)? onSelfDestructTap;
  final void Function(Map<String, dynamic> message)? onImageTap;
  final void Function(Map<String, dynamic> message)? onVideoTap;
  final void Function(Map<String, dynamic> message)? onVoiceListened;
  final ChatBubbleGroup group;

  const ChatMessageListTile({
    super.key,
    required this.peerUserId,
    required this.rowKey,
    this.onRetry,
    this.onReply,
    this.onJumpToReply,
    this.onReact,
    this.onLongPress,
    this.onSelfDestructTap,
    this.onImageTap,
    this.onVideoTap,
    this.onVoiceListened,
    this.group = ChatBubbleGroup.isolated,
  });

  @override
  ConsumerState<ChatMessageListTile> createState() =>
      _ChatMessageListTileState();
}

class _ChatMessageListTileState extends ConsumerState<ChatMessageListTile> {
  /// Latched so a later parent rebuild (gate already consumed) does not
  /// dispose the enter animation mid-flight.
  late final bool _playEnter;
  bool _contextMenuOpen = false;

  ChatThreadRowId get _rowId =>
      ChatThreadRowId(widget.peerUserId, widget.rowKey);

  @override
  void initState() {
    super.initState();
    final row = _rowId.read(ref);
    _playEnter = row != null &&
        ref
            .read(chatThreadMessagesProvider(widget.peerUserId).notifier)
            .enterGate
            .takeNew(row);
  }

  void _invoke(void Function(Map<String, dynamic> message)? fn) {
    if (fn == null) return;
    final message = _rowId.read(ref);
    if (message != null) fn(message);
  }

  Future<void> _openContextMenu(Offset at) async {
    final current = _rowId.read(ref);
    if (current == null) return;
    if (widget.onLongPress != null) {
      setState(() => _contextMenuOpen = true);
      try {
        await widget.onLongPress!(current, at: at);
      } finally {
        if (mounted) setState(() => _contextMenuOpen = false);
      }
    } else {
      widget.onReply?.call(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(chatMessageProvider(_rowId));
    if (message == null) return const SizedBox.shrink();

    final isSent = message['is_sent'] == true;
    final isDeleted = message['is_deleted'] == true;
    if (ChatScreenshotUi.isScreenshotNotice(message)) {
      return ChatSystemMessage.screenshot(
        isSent: isSent,
      );
    }
    if (ChatSystemMessage.isMatchRow(message)) {
      return ChatSystemMessage.match(
        caption: ChatSystemMessage.matchCaption(message),
      );
    }
    if (ChatScreenshotUi.isSystemRow(message)) {
      final body =
          (message['text'] ?? message['message'] ?? '').toString().trim();
      return ChatSystemMessage(
        caption: body.isEmpty ? ChatScreenshotUi.listPreview : body,
        iconPath: AppIcons.info,
      );
    }
    final deliveryStatus = ChatDeliveryStatusMap.fromMap(message);
    final reactions = ChatReactionSummary.fromMap(message);
    Widget bubble = isDeleted
        ? ChatDeletedTombstone(
            isSent: isSent,
            isFirstInGroup: widget.group.isFirstInGroup,
            isLastInGroup: widget.group.isLastInGroup,
          )
        : MessageBubble(
      key: ValueKey(
        message['client_id'] ??
            message['id'] ??
            message['timestamp']?.toString(),
      ),
      message: message['text'] ?? '',
      isSent: message['is_sent'] ?? false,
      timestamp: AppDateTime.parseApi(message['timestamp']) ??
          (message['timestamp'] is DateTime
              ? AppDateTime.toLocal(message['timestamp'] as DateTime)
              : null),
      isRead: message['is_read'] ?? false,
      isDelivered: message['is_delivered'] == true ||
          message['is_read'] == true,
      isEdited: message['is_edited'] == true,
      deliveryStatus: deliveryStatus,
      onRetry: ChatSendRetry.canRetry(message)
          ? () => _invoke(widget.onRetry)
          : null,
      messageType: message['type'] ?? 'text',
      remainingSeconds: message['remaining_seconds'] is int
          ? message['remaining_seconds'] as int
          : int.tryParse(message['remaining_seconds']?.toString() ?? ''),
      expiresInSeconds: message['expires_in_seconds'] is int
          ? message['expires_in_seconds'] as int
          : int.tryParse(message['expires_in_seconds']?.toString() ?? ''),
      mediaUrl: message['attachment_url']?.toString(),
      mediaThumbnailUrl: message['media_thumbnail_url']?.toString(),
      placeholderDataUri: message['placeholder_data_uri']?.toString(),
      mediaWidth: message['media_width'] is int
          ? message['media_width'] as int
          : int.tryParse(message['media_width']?.toString() ?? ''),
      mediaHeight: message['media_height'] is int
          ? message['media_height'] as int
          : int.tryParse(message['media_height']?.toString() ?? ''),
      mediaDuration: message['media_duration'] is int
          ? message['media_duration'] as int
          : int.tryParse(message['media_duration']?.toString() ?? ''),
      isLocked: message['is_locked'] == true,
      isBlurred: message['is_blurred'] == true,
      profileCard: message['profile_card'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(message['profile_card'] as Map)
          : null,
      heroTag: message['hero_tag']?.toString(),
      messageId: message['id'] is int ? message['id'] as int : 0,
      isExpired: message['is_expired'] == true,
      viewedAt: AppDateTime.parseApi(message['viewed_at']),
      onSelfDestructTap: message['is_sent'] != true &&
              message['is_expired'] != true &&
              message['viewed_at'] == null
          ? () => _invoke(widget.onSelfDestructTap)
          : null,
      onImageTap: widget.onImageTap == null
          ? null
          : () => _invoke(widget.onImageTap),
      onVideoTap: widget.onVideoTap == null
          ? null
          : () => _invoke(widget.onVideoTap),
      onVoiceListened: widget.onVoiceListened == null
          ? null
          : () => _invoke(widget.onVoiceListened),
      replyToName: message['reply_to_name']?.toString(),
      replyToPreview: message['reply_to_text']?.toString(),
      forwardedFromName: message['forwarded_from_name']?.toString(),
      isForwarded: message['is_forwarded'] == true ||
          message['forwarded_from_message_id'] != null ||
          message['forwarded_from_user_id'] != null,
      onReplyQuoteTap: widget.onJumpToReply == null ||
              ChatReplyJump.replyToId(message) == null
          ? null
          : () => _invoke(widget.onJumpToReply),
      clientId: message['client_id']?.toString(),
      isFirstInGroup: widget.group.isFirstInGroup,
      isLastInGroup: widget.group.isLastInGroup,
    );

    if (!isDeleted && !reactions.isEmpty) {
      bubble = Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          bubble,
          ChatReactionChips(
            counts: reactions.counts,
            mine: reactions.mine,
            isSent: isSent,
            onTap: widget.onReact == null
                ? null
                : (emoji) {
                    final current = _rowId.read(ref);
                    if (current != null) widget.onReact!(current, emoji);
                  },
          ),
        ],
      );
    }

    if (_playEnter) {
      bubble = ChatMessageEnterAnimation(
        play: true,
        isSent: message['is_sent'] == true,
        child: bubble,
      );
    }

    final reduced = !AppAnimations.animationsEnabled(context);
    bubble = AnimatedScale(
      key: const ValueKey('chat-context-menu-bubble-scale'),
      scale: !reduced && _contextMenuOpen
          ? AppAnimations.chatContextMenuBubbleScale
          : 1,
      duration:
          reduced ? Duration.zero : AppAnimations.chatContextMenu,
      curve: AppAnimations.curveDefault,
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );

    final messageId = ChatReplyJump.rowMessageId(message) ?? 0;
    final highlighted = messageId > 0 &&
        ref.watch(
          chatReplyHighlightProvider(widget.peerUserId).select(
            (id) => id == messageId,
          ),
        );
    final canSwipeReply = !isDeleted &&
        widget.onReply != null &&
        message['kind'] != 'call' &&
        messageId > 0;

    Widget row = isDeleted
        ? bubble
        : GestureDetector(
            onLongPressStart: (details) {
              unawaited(_openContextMenu(details.globalPosition));
            },
            child: bubble,
          );

    if (canSwipeReply) {
      row = ChatSwipeToReply(
        isSent: isSent,
        onReply: () {
          final current = _rowId.read(ref);
          if (current != null) widget.onReply!(current);
        },
        child: row,
      );
    }

    row = ChatReplyHighlight(
      highlighted: highlighted,
      child: row,
    );

    return RepaintBoundary(
      child: SizedBox(
        key: messageId > 0 ? ChatReplyJump.anchorKey(messageId) : null,
        width: double.infinity,
        child: row,
      ),
    );
  }
}

/// Per-bubble list row (PERF-INFRA-011). Same widget as [ChatMessageListTile].
typedef MessageRow = ChatMessageListTile;
