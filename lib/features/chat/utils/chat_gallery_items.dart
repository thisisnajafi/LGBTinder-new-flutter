import 'chat_local_media.dart';

/// One viewable photo in a chat album (CHAT-IMG-004).
class ChatGalleryItem {
  final String url;
  final String heroTag;
  final int messageId;
  final String? clientId;

  const ChatGalleryItem({
    required this.url,
    required this.heroTag,
    this.messageId = 0,
    this.clientId,
  });

  bool get isLocal => ChatLocalMedia.isLocalPath(url);

  static String heroTagFor({int? messageId, String? clientId}) {
    if (messageId != null && messageId > 0) {
      return 'chat_image_$messageId';
    }
    final client = clientId?.trim();
    if (client != null && client.isNotEmpty) {
      return client.startsWith('chat_image_') ? client : 'chat_image_$client';
    }
    return 'chat_image_pending';
  }
}

/// Collects swipeable image messages from the thread map list.
class ChatGalleryItems {
  ChatGalleryItems._();

  static bool isGalleryImage(Map<String, dynamic> message) {
    final kind = message['kind']?.toString();
    if (kind == 'call' || kind == 'date_badge' || kind == 'unread_separator') {
      return false;
    }
    final type = message['type']?.toString() ?? 'text';
    if (type != 'image') return false;
    if (message['is_locked'] == true) return false;
    if (message['is_expired'] == true) return false;
    final url = message['attachment_url']?.toString();
    return url != null && url.isNotEmpty;
  }

  static ChatGalleryItem? itemFromMap(Map<String, dynamic> message) {
    if (!isGalleryImage(message)) return null;
    final url = message['attachment_url']!.toString();
    final id = message['id'] is int
        ? message['id'] as int
        : int.tryParse(message['id']?.toString() ?? '') ?? 0;
    return ChatGalleryItem(
      url: url,
      heroTag: ChatGalleryItem.heroTagFor(
        messageId: id,
        clientId: message['client_id']?.toString(),
      ),
      messageId: id,
      clientId: message['client_id']?.toString(),
    );
  }

  static List<ChatGalleryItem> fromMaps(Iterable<Map<String, dynamic>> messages) {
    final items = <ChatGalleryItem>[];
    final seen = <String>{};
    for (final message in messages) {
      final item = itemFromMap(message);
      if (item == null) continue;
      final key = item.clientId?.isNotEmpty == true
          ? 'c:${item.clientId}'
          : (item.messageId > 0 ? 'id:${item.messageId}' : item.url);
      if (!seen.add(key)) continue;
      items.add(item);
    }
    return items;
  }

  static int indexFor(
    List<ChatGalleryItem> items,
    Map<String, dynamic> message,
  ) {
    final clientId = message['client_id']?.toString();
    if (clientId != null && clientId.isNotEmpty) {
      final byClient = items.indexWhere((item) => item.clientId == clientId);
      if (byClient >= 0) return byClient;
    }
    final id = message['id'] is int
        ? message['id'] as int
        : int.tryParse(message['id']?.toString() ?? '') ?? 0;
    if (id > 0) {
      final byId = items.indexWhere((item) => item.messageId == id);
      if (byId >= 0) return byId;
    }
    final url = message['attachment_url']?.toString();
    if (url != null && url.isNotEmpty) {
      final byUrl = items.indexWhere((item) => item.url == url);
      if (byUrl >= 0) return byUrl;
    }
    return 0;
  }
}
