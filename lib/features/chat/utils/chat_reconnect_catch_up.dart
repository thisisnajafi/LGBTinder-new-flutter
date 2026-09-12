import '../data/models/message.dart';
import '../data/services/chat_service.dart';

/// Reconnect gap fill via `after_id` (CHAT-OFFLINE-002).
class ChatReconnectCatchUp {
  ChatReconnectCatchUp._();

  static const int pageSize = 100;
  static const int maxPages = 50;

  static int? lastServerId(Iterable<Map<String, dynamic>> rows) {
    int? highest;
    for (final row in rows) {
      final kind = row['kind']?.toString();
      if (kind != null && kind != 'message') continue;
      final raw = row['id'];
      final id = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
      if (id <= 0) continue;
      if (highest == null || id > highest) highest = id;
    }
    return highest;
  }

  static int? nextAfterId({
    required ChatHistoryResult page,
    required int currentAfterId,
  }) {
    if (!page.hasMore || page.messages.isEmpty) return null;
    final cursor = page.nextAfterId;
    if (cursor != null && cursor > currentAfterId) return cursor;
    var highest = currentAfterId;
    for (final message in page.messages) {
      if (message.id > highest) highest = message.id;
    }
    return highest > currentAfterId ? highest : null;
  }

  /// Walks `after_id` pages until empty. Incoming pages are newest-first.
  static Future<List<Message>> fetchAllAfter({
    required Future<ChatHistoryResult> Function(int afterId) fetchPage,
    required int lastId,
  }) async {
    final collected = <Message>[];
    var afterId = lastId;
    final seen = <int>{};
    for (var i = 0; i < maxPages; i++) {
      final page = await fetchPage(afterId);
      if (page.messages.isEmpty) break;
      for (final message in page.messages.reversed) {
        if (message.id <= 0 || seen.contains(message.id)) continue;
        seen.add(message.id);
        collected.add(message);
      }
      final next = nextAfterId(page: page, currentAfterId: afterId);
      if (next == null) break;
      afterId = next;
    }
    return collected;
  }
}
