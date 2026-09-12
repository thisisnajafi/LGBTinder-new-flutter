import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/chat.dart';
import 'chat_list_preview_provider.dart';

/// In-memory cache of peer user IDs whose conversations are pinned.
final conversationPinCacheProvider =
    NotifierProvider<ConversationPinCacheNotifier, Set<int>>(
  ConversationPinCacheNotifier.new,
);

class ConversationPinCacheNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void seedFromChats(Iterable<Chat> chats) {
    state = {
      for (final chat in chats)
        if (chat.isPinned) chat.userId,
    };
  }

  void setPinned(int userId, bool pinned) {
    final next = {...state};
    if (pinned) {
      next.add(userId);
    } else {
      next.remove(userId);
    }
    state = next;
    ref.read(chatListPreviewProvider.notifier).setPinned(userId, pinned);
  }

  void seedIds(Iterable<int> ids) {
    if (ids.isEmpty) return;
    state = {...state, ...ids};
  }

  bool isPinned(int userId) => state.contains(userId);

  void clearAll() {
    state = {};
  }
}
