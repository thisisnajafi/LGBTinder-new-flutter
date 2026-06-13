import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/chat.dart';

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
  }

  bool isMuted(int userId) => state.contains(userId);

  void clearAll() {
    state = {};
  }
}
