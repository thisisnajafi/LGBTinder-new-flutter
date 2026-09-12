import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only hidden conversation peers (CHAT-MSG-006).
///
/// There is no conversation-delete API; rows are filtered locally and Undo
/// restores them. Logout / [clear] drops the set.
final chatListHiddenPeersProvider =
    NotifierProvider<ChatListHiddenPeersNotifier, Set<int>>(
  ChatListHiddenPeersNotifier.new,
);

class ChatListHiddenPeersNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void hide(int userId) {
    if (userId <= 0 || state.contains(userId)) return;
    state = {...state, userId};
  }

  void restore(int userId) {
    if (!state.contains(userId)) return;
    final next = {...state}..remove(userId);
    state = next;
  }

  void clear() {
    if (state.isEmpty) return;
    state = {};
  }
}
