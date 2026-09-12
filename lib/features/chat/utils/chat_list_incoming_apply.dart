/// Pure list-preview rules for a Pusher `MessageSent` (CHAT-RT-006).
class ChatListIncomingApply {
  ChatListIncomingApply._();

  static const placeholderName = 'User';

  static int peerId({
    required int senderId,
    required int receiverId,
    required int currentUserId,
  }) {
    return senderId == currentUserId ? receiverId : senderId;
  }

  static bool isIncoming({
    required int senderId,
    required int currentUserId,
  }) {
    return senderId != currentUserId;
  }

  static bool isOpenThread({
    required int peerId,
    int? activeChatPeerId,
  }) {
    return activeChatPeerId != null &&
        activeChatPeerId > 0 &&
        activeChatPeerId == peerId;
  }

  static bool shouldIncrementUnread({
    required bool isIncoming,
    required bool isOpenThread,
  }) {
    return isIncoming && !isOpenThread;
  }

  /// Skip replayed / older events so catch-up does not rewind the preview.
  static bool shouldReplacePreview({
    required int messageId,
    required DateTime createdAt,
    required int lastMessageId,
    DateTime? lastMessageTime,
  }) {
    if (messageId > 0 && lastMessageId > 0) {
      return messageId > lastMessageId;
    }
    if (lastMessageTime == null) return true;
    return createdAt.isAfter(lastMessageTime);
  }

  static int nextUnreadCount({
    required int currentUnread,
    required bool increment,
    required bool isOpenThread,
  }) {
    if (isOpenThread) return 0;
    if (increment) return currentUnread + 1;
    return currentUnread;
  }

  static String resolveName({
    required bool isIncoming,
    String? payloadName,
    String? existingName,
  }) {
    final existing = existingName?.trim() ?? '';
    if (existing.isNotEmpty && existing != placeholderName) {
      return existing;
    }
    if (isIncoming) {
      final payload = payloadName?.trim() ?? '';
      if (payload.isNotEmpty && payload != placeholderName) return payload;
    }
    return existing.isNotEmpty ? existing : placeholderName;
  }

  static String? resolveAvatar({
    required bool isIncoming,
    String? payloadAvatar,
    String? existingAvatar,
    String? cachedAvatar,
  }) {
    final existing = existingAvatar?.trim();
    if (existing != null && existing.isNotEmpty) return existingAvatar;
    if (isIncoming) {
      final payload = payloadAvatar?.trim();
      if (payload != null && payload.isNotEmpty) return payloadAvatar;
    }
    final cached = cachedAvatar?.trim();
    if (cached != null && cached.isNotEmpty) return cachedAvatar;
    return existingAvatar;
  }

  static bool needsHydrate({
    required String name,
    String? avatarUrl,
  }) {
    final avatar = avatarUrl?.trim() ?? '';
    return name.trim().isEmpty ||
        name.trim() == placeholderName ||
        avatar.isEmpty;
  }
}
