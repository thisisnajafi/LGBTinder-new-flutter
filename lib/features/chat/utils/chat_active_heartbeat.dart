/// Helpers for CHAT-NOTIF-003 backend active-chat heartbeats.
class ChatActiveHeartbeat {
  ChatActiveHeartbeat._();

  static const interval = Duration(minutes: 3);

  /// Real conversation rows only — messenger list historically used peer user id as `chat.id`.
  static int? reportableConversationId({int? conversationId, int? peerUserId}) {
    if (conversationId == null || conversationId <= 0) {
      return null;
    }
    if (peerUserId != null && conversationId == peerUserId) {
      return null;
    }
    return conversationId;
  }

  /// The server skips a message push while this is true. Only the foreground
  /// thread counts — a backgrounded chat must still notify (RT-009).
  static bool shouldReportActive({
    required bool appInForeground,
    required int? conversationId,
    required int? peerUserId,
  }) {
    if (!appInForeground) return false;
    return reportableConversationId(
          conversationId: conversationId,
          peerUserId: peerUserId,
        ) !=
        null;
  }
}
