import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../data/local/chat_info_cache.dart';
import 'chat_providers.dart';

/// Live pinned-bar snapshot for one peer (CHAT-FEAT-005, MVP one pin).
class ChatPinnedBannerSnapshot {
  final int count;
  final int? messageId;
  final String? preview;

  const ChatPinnedBannerSnapshot({
    this.count = 0,
    this.messageId,
    this.preview,
  });

  bool get isVisible => count > 0;

  bool isPinned(int messageId) =>
      messageId > 0 && this.messageId == messageId;
}

class ChatPinnedBannerNotifier extends StateNotifier<ChatPinnedBannerSnapshot> {
  ChatPinnedBannerNotifier(this._ref, this._userId)
      : super(const ChatPinnedBannerSnapshot()) {
    final cached =
        _ref.read(chatInfoCacheProvider.notifier).snapshotFor(_userId).pinnedCount;
    if (cached > 0) {
      state = ChatPinnedBannerSnapshot(count: cached);
    }
    unawaited(_hydrate());
  }

  final Ref _ref;
  final int _userId;

  Future<void> _hydrate() async {
    if (_userId <= 0) return;
    try {
      final pinned =
          await _ref.read(chatServiceProvider).getPinnedMessages(_userId);
      if (!mounted) return;
      if (pinned.isEmpty) {
        state = const ChatPinnedBannerSnapshot();
        await _ref.read(chatInfoCacheProvider.notifier).savePinnedCount(_userId, 0);
        return;
      }
      final first = pinned.first;
      state = ChatPinnedBannerSnapshot(
        count: 1,
        messageId: first.id,
        preview: first.message,
      );
      await _ref.read(chatInfoCacheProvider.notifier).savePinnedCount(_userId, 1);
    } catch (e) {
      AppLogger.warning(
        'Pinned banner hydrate failed',
        tag: 'Chat',
        error: e,
      );
    }
  }

  void applyPinned({
    required int messageId,
    String? preview,
  }) {
    if (messageId <= 0) return;
    state = ChatPinnedBannerSnapshot(
      count: 1,
      messageId: messageId,
      preview: preview,
    );
    unawaited(
      _ref.read(chatInfoCacheProvider.notifier).savePinnedCount(_userId, 1),
    );
  }

  void applyUnpinned(int messageId) {
    if (!state.isPinned(messageId) && state.count <= 0) return;
    if (state.messageId != null && state.messageId != messageId) return;
    state = const ChatPinnedBannerSnapshot();
    unawaited(
      _ref.read(chatInfoCacheProvider.notifier).savePinnedCount(_userId, 0),
    );
  }
}

final chatPinnedBannerProvider = StateNotifierProvider.autoDispose
    .family<ChatPinnedBannerNotifier, ChatPinnedBannerSnapshot, int>(
  (ref, userId) => ChatPinnedBannerNotifier(ref, userId),
);
