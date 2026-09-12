import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_logger.dart';
import '../data/local/chat_database_provider.dart';
import '../data/models/chat.dart';
import 'chat_list_preview_provider.dart';

/// Bridge for non-Riverpod services (FCM) to read mute state.
class ConversationMuteBridge {
  static bool Function(int peerUserId)? isPeerMuted;
}

/// In-memory cache of peer user IDs whose conversations are muted.
final conversationMuteCacheProvider =
    NotifierProvider<ConversationMuteCacheNotifier, Set<int>>(
  ConversationMuteCacheNotifier.new,
);

class ConversationMuteCacheNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    ConversationMuteBridge.isPeerMuted = (userId) => state.contains(userId);
    ref.onDispose(() {
      ConversationMuteBridge.isPeerMuted = null;
    });
    return {};
  }

  void seedFromChats(Iterable<Chat> chats) {
    state = {
      for (final chat in chats)
        if (chat.isMuted) chat.userId,
    };
  }

  void setMuted(int userId, bool muted) {
    final next = {...state};
    if (muted) {
      next.add(userId);
    } else {
      next.remove(userId);
    }
    state = next;
    ref.read(chatListPreviewProvider.notifier).setMuted(userId, muted);
    unawaited(
      ref.read(chatLocalRepositoryProvider).setConversationMuted(userId, muted),
    );
  }

  void seedIds(Iterable<int> ids) {
    if (ids.isEmpty) return;
    state = {...state, ...ids};
  }

  bool isMuted(int userId) => state.contains(userId);

  void clearAll() {
    state = {};
  }
}

/// Loads muted peer IDs from SQLite so FCM can suppress sounds before the list page mounts.
final conversationMuteSeedProvider = Provider<void>((ref) {
  ref.watch(chatLocalInitProvider);
  final cache = ref.read(conversationMuteCacheProvider.notifier);
  unawaited(() async {
    try {
      final ids = await ref.read(chatLocalRepositoryProvider).getMutedPeerIds();
      cache.seedIds(ids);
    } catch (e) {
      AppLogger.warning(
        'Failed to seed conversation mute cache',
        tag: 'Chat',
        error: e,
      );
    }
  }());
});
