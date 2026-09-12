import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import 'chat_thread_scroll.dart';
import 'chat_timeline_slots.dart';

/// Scroll-to-original for in-bubble quotes (CHAT-BUBBLE-005 / CHAT-THREAD-006).
class ChatReplyJump {
  ChatReplyJump._();

  static const String notLoadedMessage = 'Original message is not loaded yet';

  static const String searchingMessage = 'Finding original message…';

  /// Cap so a deleted original cannot page forever (CHAT-THREAD-006).
  static const int maxHistoryPages = 12;

  /// Whether another `before_id` page should be requested while seeking.
  static bool shouldKeepPaginating({
    required bool found,
    required bool hasMore,
    required bool loadFailed,
    required int pagesLoaded,
    bool emptyPage = false,
    int maxPages = maxHistoryPages,
  }) {
    if (found || loadFailed || !hasMore || emptyPage) return false;
    return pagesLoaded < maxPages;
  }

  static final Map<int, GlobalObjectKey> _anchors = <int, GlobalObjectKey>{};

  static GlobalObjectKey anchorKey(int messageId) {
    return _anchors.putIfAbsent(
      messageId,
      () => GlobalObjectKey(_ChatReplyAnchorId(messageId)),
    );
  }

  static int? replyToId(Map<String, dynamic> message) {
    final raw = message['reply_to_message_id'];
    if (raw is int) return raw > 0 ? raw : null;
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static int? rowMessageId(Map<String, dynamic> message) {
    final raw = message['id'];
    if (raw is int) return raw > 0 ? raw : null;
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// Reverse-list builder index for [rowKey], or null if the slot is missing.
  static int? visualIndex({
    required List<ChatTimelineSlot> slots,
    required String rowKey,
  }) {
    final chrono = slots.indexWhere((slot) => slot.key == rowKey);
    if (chrono < 0) return null;
    return ChatThreadScroll.chronologicalIndex(slots.length, chrono);
  }

  /// Linear estimate of reverse-list pixels for [rowKey].
  static double? estimatedPixels({
    required List<ChatTimelineSlot> slots,
    required String rowKey,
    required double maxScrollExtent,
  }) {
    final visual = visualIndex(slots: slots, rowKey: rowKey);
    if (visual == null) return null;
    if (slots.length <= 1) return ChatThreadScroll.latestPixels;
    final pixels = maxScrollExtent * (visual / (slots.length - 1));
    if (pixels < ChatThreadScroll.latestPixels) {
      return ChatThreadScroll.latestPixels;
    }
    if (pixels > maxScrollExtent) return maxScrollExtent;
    return pixels;
  }

  static Future<bool> ensureVisible(
    int messageId, {
    required BuildContext context,
    double alignment = 0.35,
  }) async {
    if (messageId <= 0) return false;
    final target = anchorKey(messageId).currentContext;
    if (target == null) return false;
    await Scrollable.ensureVisible(
      target,
      alignment: alignment,
      duration: AppAnimations.chatJumpToReplyDuration(context),
      curve: AppAnimations.curveDefault,
    );
    return true;
  }
}

class _ChatReplyAnchorId {
  const _ChatReplyAnchorId(this.messageId);

  final int messageId;

  @override
  bool operator ==(Object other) =>
      other is _ChatReplyAnchorId && other.messageId == messageId;

  @override
  int get hashCode => messageId;
}
