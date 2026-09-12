/// Normalizes a Pusher `MessageSent` envelope into `Message.fromJson` input.
class ChatMessageSentPayload {
  ChatMessageSentPayload._();

  static Map<String, dynamic>? messageJson(Map<String, dynamic> data) {
    Map<String, dynamic>? messageJson;
    final messageData = data['message'];
    if (messageData is Map) {
      messageJson = Map<String, dynamic>.from(messageData);
    } else if (data['id'] != null && data['sender_id'] != null) {
      messageJson = Map<String, dynamic>.from(data);
    }
    if (messageJson == null) return null;

    if (messageJson['conversation_id'] == null &&
        data['conversation_id'] != null) {
      messageJson['conversation_id'] = data['conversation_id'];
    }

    final senderData = data['sender'];
    if (senderData is Map) {
      messageJson['sender'] = Map<String, dynamic>.from(senderData);
      final name = senderData['display_name'] ?? senderData['name'];
      if (name != null &&
          (messageJson['sender_name'] == null ||
              messageJson['sender_name'].toString().trim().isEmpty)) {
        messageJson['sender_name'] = name;
      }
      final avatar = senderData['avatar_url'];
      if (avatar != null &&
          (messageJson['sender_avatar_url'] == null ||
              messageJson['sender_avatar_url'].toString().trim().isEmpty)) {
        messageJson['sender_avatar_url'] = avatar;
      }
    }

    return messageJson;
  }
}
