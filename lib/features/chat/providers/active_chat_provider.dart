import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_pusher_providers.dart';

/// The 1:1 chat the user is currently looking at.
class ActiveChatSession {
  const ActiveChatSession({
    this.conversationId,
    this.peerUserId,
  });

  final int? conversationId;
  final int? peerUserId;

  bool get hasPeer => peerUserId != null && peerUserId! > 0;

  bool get isSubscribed => conversationId != null && conversationId! > 0;

  bool isPeer(int userId) => hasPeer && peerUserId == userId;

  bool isConversation(int id) => isSubscribed && conversationId == id;
}

/// Global active-chat snapshot. Non-null [ActiveChatSession.conversationId]
/// after Pusher (or local tracking) has subscribed to that thread.
final activeChatSessionProvider = Provider<ActiveChatSession>((ref) {
  final lifecycle = ref.watch(chatPusherLifecycleProvider);
  return ActiveChatSession(
    conversationId: lifecycle.activeConversationId,
    peerUserId: lifecycle.activePeerUserId,
  );
});

final activeChatConversationIdProvider = Provider<int?>((ref) {
  return ref.watch(activeChatSessionProvider).conversationId;
});

final activeChatPeerUserIdProvider = Provider<int?>((ref) {
  return ref.watch(activeChatSessionProvider).peerUserId;
});
