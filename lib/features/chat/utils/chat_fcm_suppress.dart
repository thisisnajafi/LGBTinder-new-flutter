/// Pure helpers so FCM can suppress chat banners without Firebase in tests.
class ChatFcmSuppress {
  ChatFcmSuppress._();

  static const _chatTypes = {'message', 'chat', 'new_message'};

  static bool isChatPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim().toLowerCase() ?? '';
    return _chatTypes.contains(type);
  }

  static int? senderId(Map<String, dynamic> data) {
    return _positiveInt(
      data['sender_id'] ?? data['user_id'] ?? data['from_user_id'],
    );
  }

  static int? conversationId(Map<String, dynamic> data) {
    return _positiveInt(
      data['conversation_id'] ?? data['chat_id'],
    );
  }

  static bool matchesOpenChat(
    Map<String, dynamic> data, {
    int? activePeerUserId,
    int? activeConversationId,
    bool Function(int senderId)? isActivePeer,
    bool Function(int conversationId)? isActiveConversation,
  }) {
    if (!isChatPayload(data)) return false;

    final conv = conversationId(data);
    if (conv != null) {
      if (isActiveConversation?.call(conv) == true) return true;
      if (activeConversationId != null && activeConversationId == conv) {
        return true;
      }
    }

    final sender = senderId(data);
    if (sender != null) {
      if (isActivePeer?.call(sender) == true) return true;
      if (activePeerUserId != null && activePeerUserId == sender) return true;
    }
    return false;
  }

  static bool shouldSuppress(
    Map<String, dynamic> data, {
    int? activePeerUserId,
    int? activeConversationId,
    bool Function(int senderId)? isActivePeer,
    bool Function(int conversationId)? isActiveConversation,
    bool Function(int senderId)? isMutedPeer,
  }) {
    if (!isChatPayload(data)) return false;
    if (matchesOpenChat(
      data,
      activePeerUserId: activePeerUserId,
      activeConversationId: activeConversationId,
      isActivePeer: isActivePeer,
      isActiveConversation: isActiveConversation,
    )) {
      return true;
    }
    final sender = senderId(data);
    if (sender != null && (isMutedPeer?.call(sender) ?? false)) {
      return true;
    }
    return false;
  }

  static int? _positiveInt(Object? raw) {
    if (raw == null) return null;
    final id = raw is int ? raw : int.tryParse(raw.toString());
    if (id == null || id <= 0) return null;
    return id;
  }
}
