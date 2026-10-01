import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/services/app_logger.dart';
import '../data/local/chat_database_provider.dart';
import 'chat_list_hidden_peers_provider.dart';
import 'chat_list_preview_provider.dart';
import 'chat_providers.dart';
import 'chat_thread_providers.dart';
import 'conversation_mute_cache_provider.dart';
import 'conversation_pin_cache_provider.dart';

/// Holds a conversation off the list, then deletes it after [undoWindow].
final chatConversationDeleteQueueProvider =
    NotifierProvider<ChatConversationDeleteQueue, Set<int>>(
  ChatConversationDeleteQueue.new,
);

class ChatConversationDeleteQueue extends Notifier<Set<int>> {
  ChatConversationDeleteQueue({
    this.undoWindow = AppAnimations.chatListDeleteUndo,
  });

  final Duration undoWindow;
  final Map<int, Timer> _timers = {};

  @override
  Set<int> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return {};
  }

  void schedule(int userId) {
    if (userId <= 0) return;
    _timers.remove(userId)?.cancel();
    _timers[userId] = Timer(undoWindow, () {
      unawaited(commit(userId));
    });
    if (!state.contains(userId)) {
      state = {...state, userId};
    }
  }

  /// Returns false when the undo window already elapsed.
  bool undo(int userId) {
    final timer = _timers.remove(userId);
    if (timer == null) return false;
    timer.cancel();
    final next = {...state}..remove(userId);
    state = next;
    ref.read(chatListHiddenPeersProvider.notifier).restore(userId);
    return true;
  }

  Future<void> commit(int userId) async {
    _timers.remove(userId)?.cancel();
    try {
      await ref.read(chatServiceProvider).deleteConversation(userId);
      await ref.read(chatLocalRepositoryProvider).purgePeer(userId);
      ref.read(chatListPreviewProvider.notifier).removePeer(userId);
      ref.read(conversationPinCacheProvider.notifier).setPinned(userId, false);
      ref.read(conversationMuteCacheProvider.notifier).setMuted(userId, false);
      ref.read(chatThreadMessagesProvider(userId).notifier).clear();
      ref.read(chatListHiddenPeersProvider.notifier).restore(userId);
    } catch (e, stack) {
      AppLogger.error(
        'Conversation delete failed',
        tag: 'Chat',
        error: e,
        stackTrace: stack,
      );
      ref.read(chatListHiddenPeersProvider.notifier).restore(userId);
    } finally {
      if (state.contains(userId)) {
        final next = {...state}..remove(userId);
        state = next;
      }
    }
  }
}
