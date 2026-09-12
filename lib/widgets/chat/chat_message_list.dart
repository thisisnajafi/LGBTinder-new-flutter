import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../features/calls/data/models/call.dart';
import '../../features/calls/presentation/widgets/call_history_bubble.dart';
import '../../features/chat/presentation/widgets/chat_empty_conversation.dart';
import '../../features/chat/providers/chat_thread_providers.dart';
import '../../features/chat/utils/chat_bubble_group.dart';
import '../../features/chat/utils/chat_thread_scroll.dart';
import '../../features/chat/utils/chat_timeline_slots.dart';
import '../../features/chat/utils/chat_unread_separator.dart';
import '../error_handling/error_display_widget.dart';
import '../loading/skeleton_chat.dart';
import 'chat_date_badge.dart';
import 'chat_load_older_retry.dart';
import 'chat_message_list_tile.dart';
import 'chat_peer_typing_indicator.dart';
import 'chat_sticky_date_header.dart';
import 'chat_thread_jump_fab_layer.dart';
import 'chat_thread_list_view.dart';
import 'chat_unread_separator_bar.dart';

/// Reverse timeline, load flags, and empty/error chrome (CHAT-PERF-007).
///
/// Chrome and slot identity are selected separately so a row patch does not
/// rebuild the list parent (CHAT-PERF-003).
class ChatMessageList extends ConsumerWidget {
  final int peerUserId;
  final String peerDisplayName;
  final int currentUserId;
  final ScrollController scrollController;
  final GlobalKey threadListKey;
  final GlobalKey unreadSeparatorKey;
  final bool showUnreadSeparator;
  final int openUnreadCount;
  final VoidCallback onRetryLoad;
  final VoidCallback onRetryLoadOlder;
  final ValueChanged<String> onSendOpener;
  final VoidCallback onJumpToLatest;
  final ValueChanged<Call> onRedialCall;
  final void Function(Map<String, dynamic> message) onRetryFailed;
  final void Function(Map<String, dynamic> message) onReply;
  final void Function(Map<String, dynamic> message)? onJumpToReply;
  final void Function(Map<String, dynamic> message, String emoji)? onReact;
  final ChatMessageLongPressCallback onLongPress;
  final void Function(Map<String, dynamic> message) onSelfDestructTap;
  final void Function(Map<String, dynamic> message) onImageTap;
  final void Function(Map<String, dynamic> message) onVideoTap;
  final void Function(Map<String, dynamic> message)? onVoiceListened;

  const ChatMessageList({
    super.key,
    required this.peerUserId,
    required this.peerDisplayName,
    required this.currentUserId,
    required this.scrollController,
    required this.threadListKey,
    required this.unreadSeparatorKey,
    required this.showUnreadSeparator,
    required this.openUnreadCount,
    required this.onRetryLoad,
    required this.onRetryLoadOlder,
    required this.onSendOpener,
    required this.onJumpToLatest,
    required this.onRedialCall,
    required this.onRetryFailed,
    required this.onReply,
    this.onJumpToReply,
    this.onReact,
    required this.onLongPress,
    required this.onSelfDestructTap,
    required this.onImageTap,
    required this.onVideoTap,
    this.onVoiceListened,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ref.watch(
      chatThreadMessagesProvider(peerUserId).select(
        (s) => ChatThreadChrome(
          isLoading: s.isLoading,
          hasError: s.hasError,
          errorMessage: s.errorMessage,
          isEmpty: s.rows.isEmpty,
          isLoadingMore: s.isLoadingMore,
          loadMoreFailed: s.loadMoreFailed,
        ),
      ),
    );
    if (chrome.isLoading) {
      return const SkeletonChat();
    }
    if (chrome.hasError) {
      return ErrorDisplayWidget(
        errorMessage: chrome.errorMessage ?? 'Failed to load messages',
        onRetry: onRetryLoad,
      );
    }
    if (chrome.isEmpty) {
      return ChatEmptyConversation(
        peerName: peerDisplayName,
        onSendOpener: onSendOpener,
      );
    }

    return Column(
      children: [
        if (chrome.isLoadingMore)
          const ChatLoadOlderSpinner()
        else if (chrome.loadMoreFailed)
          ChatLoadOlderRetry(onRetry: onRetryLoadOlder),
        Expanded(
          child: _ChatMessageTimeline(
            peerUserId: peerUserId,
            currentUserId: currentUserId,
            unreadCount: showUnreadSeparator ? openUnreadCount : 0,
            scrollController: scrollController,
            threadListKey: threadListKey,
            unreadSeparatorKey: unreadSeparatorKey,
            onJumpToLatest: onJumpToLatest,
            onRedialCall: onRedialCall,
            onRetryFailed: onRetryFailed,
            onReply: onReply,
            onJumpToReply: onJumpToReply,
            onReact: onReact,
            onLongPress: onLongPress,
            onSelfDestructTap: onSelfDestructTap,
            onImageTap: onImageTap,
            onVideoTap: onVideoTap,
            onVoiceListened: onVoiceListened,
          ),
        ),
        ChatPeerTypingIndicator(
          peerUserId: peerUserId,
          displayName: peerDisplayName,
          onAppearedAtBottom: () {
            if (!scrollController.hasClients) return;
            final pixels = scrollController.position.pixels;
            if (!ChatThreadScroll.isNearLatest(pixels: pixels)) return;
            final reduced = !AppAnimations.animationsEnabled(context);
            if (reduced) {
              scrollController.jumpTo(ChatThreadScroll.latestPixels);
              return;
            }
            scrollController.animateTo(
              ChatThreadScroll.latestPixels,
              duration: AppAnimations.chatTypingExit,
              curve: AppAnimations.curveDefault,
            );
          },
        ),
      ],
    );
  }
}

class _ChatMessageTimeline extends ConsumerWidget {
  final int peerUserId;
  final int currentUserId;
  final int unreadCount;
  final ScrollController scrollController;
  final GlobalKey threadListKey;
  final GlobalKey unreadSeparatorKey;
  final VoidCallback onJumpToLatest;
  final ValueChanged<Call> onRedialCall;
  final void Function(Map<String, dynamic> message) onRetryFailed;
  final void Function(Map<String, dynamic> message) onReply;
  final void Function(Map<String, dynamic> message)? onJumpToReply;
  final void Function(Map<String, dynamic> message, String emoji)? onReact;
  final ChatMessageLongPressCallback onLongPress;
  final void Function(Map<String, dynamic> message) onSelfDestructTap;
  final void Function(Map<String, dynamic> message) onImageTap;
  final void Function(Map<String, dynamic> message) onVideoTap;
  final void Function(Map<String, dynamic> message)? onVoiceListened;

  const _ChatMessageTimeline({
    required this.peerUserId,
    required this.currentUserId,
    required this.unreadCount,
    required this.scrollController,
    required this.threadListKey,
    required this.unreadSeparatorKey,
    required this.onJumpToLatest,
    required this.onRedialCall,
    required this.onRetryFailed,
    required this.onReply,
    this.onJumpToReply,
    required this.onReact,
    required this.onLongPress,
    required this.onSelfDestructTap,
    required this.onImageTap,
    required this.onVideoTap,
    this.onVoiceListened,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(
      chatThreadMessagesProvider(peerUserId).select((s) {
        final decorated = ChatUnreadSeparator.insert(
          items: ChatDateBadgeInserter.wrap(s.rows),
          unreadCount: unreadCount,
        );
        return ChatTimelineSlots.build(decoratedRows: decorated);
      }),
    );
    final grouping = ChatBubbleGrouping.fromSlots(slots);
    final headerTimeline = [
      for (final slot in slots)
        {
          'kind': switch (slot.kind) {
            ChatTimelineSlotKind.date => ChatDateBadgeInserter.kind,
            ChatTimelineSlotKind.unread => ChatUnreadSeparator.kind,
            ChatTimelineSlotKind.call => 'call',
            ChatTimelineSlotKind.message => 'message',
          },
          if (slot.label != null) 'label': slot.label,
        },
    ];

    return Stack(
      children: [
        ChatListView(
          key: threadListKey,
          controller: scrollController,
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[ChatThreadScroll.chronologicalIndex(
              slots.length,
              index,
            )];
            switch (slot.kind) {
              case ChatTimelineSlotKind.date:
                return ChatDateBadge(
                  key: ValueKey(slot.key),
                  label: slot.label ?? '',
                );
              case ChatTimelineSlotKind.unread:
                return ChatUnreadSeparatorBar(
                  key: unreadSeparatorKey,
                  count: slot.unreadCount,
                );
              case ChatTimelineSlotKind.call:
                return _CallHistoryRow(
                  key: ValueKey(slot.key),
                  peerUserId: peerUserId,
                  rowKey: slot.key,
                  currentUserId: currentUserId,
                  onRedialCall: onRedialCall,
                );
              case ChatTimelineSlotKind.message:
                return MessageRow(
                  key: ValueKey(slot.key),
                  peerUserId: peerUserId,
                  rowKey: slot.key,
                  group: grouping[slot.key] ?? ChatBubbleGroup.isolated,
                  onRetry: onRetryFailed,
                  onReply: onReply,
                  onJumpToReply: onJumpToReply,
                  onReact: onReact,
                  onLongPress: onLongPress,
                  onSelfDestructTap: onSelfDestructTap,
                  onImageTap: onImageTap,
                  onVideoTap: onVideoTap,
                  onVoiceListened: onVoiceListened,
                );
            }
          },
        ),
        ChatStickyDateHeader(
          controller: scrollController,
          timeline: headerTimeline,
          listKey: threadListKey,
        ),
        ChatThreadJumpFabLayer(
          peerUserId: peerUserId,
          onPressed: onJumpToLatest,
        ),
      ],
    );
  }
}

class _CallHistoryRow extends ConsumerWidget {
  final int peerUserId;
  final String rowKey;
  final int currentUserId;
  final ValueChanged<Call> onRedialCall;

  const _CallHistoryRow({
    super.key,
    required this.peerUserId,
    required this.rowKey,
    required this.currentUserId,
    required this.onRedialCall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(
      chatMessageProvider(ChatThreadRowId(peerUserId, rowKey)),
    );
    final call = row?['call'];
    if (call is! Call) return const SizedBox.shrink();
    return CallHistoryBubble(
      call: call,
      currentUserId: currentUserId,
      timestamp: row?['timestamp'] is DateTime
          ? row!['timestamp'] as DateTime
          : null,
      onTap: () => onRedialCall(call),
    );
  }
}
