/// Helpers for CHAT-NOTIF-003 backend active-chat heartbeats.
class ChatActiveHeartbeat {
  ChatActiveHeartbeat._();

  static const interval = Duration(minutes: 3);

  /// Real conversation rows only — messenger list historically used peer user id as `chat.id`.
  static int? reportableConversationId({
    int? conversationId,
    int? peerUserId,
  }) {
    if (conversationId == null || conversationId <= 0) {
      return null;
    }
    if (peerUserId != null && conversationId == peerUserId) {
      return null;
    }
    return conversationId;
  }
}
