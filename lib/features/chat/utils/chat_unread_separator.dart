/// Inserts an unread divider before the first of the last [unreadCount]
/// incoming messages (CHAT-UX-003).
class ChatUnreadSeparator {
  ChatUnreadSeparator._();

  static const String kind = 'unread_separator';

  static String labelForCount(int count) {
    if (count <= 1) return '1 new message';
    return '$count new messages';
  }

  static String bannerLabel(int count) => '— ${labelForCount(count)} —';

  static int unreadCountOfPeer({
    required int peerUserId,
    required Iterable<({int id, int unreadCount})> items,
  }) {
    for (final item in items) {
      if (item.id == peerUserId) return item.unreadCount;
    }
    return 0;
  }

  static bool isSeparator(Map<String, dynamic> item) =>
      item['kind'] == kind;

  static bool isStructuralKind(String? kind) =>
      kind == 'call' || kind == 'date_badge' || kind == ChatUnreadSeparator.kind;

  static List<Map<String, dynamic>> insert({
    required List<Map<String, dynamic>> items,
    required int unreadCount,
  }) {
    if (unreadCount <= 0 || items.isEmpty) return items;

    final incoming = <int>[];
    for (var i = 0; i < items.length; i++) {
      if (!_isIncomingMessage(items[i])) continue;
      incoming.add(i);
    }
    if (incoming.isEmpty) return items;

    final visibleUnread = unreadCount.clamp(1, incoming.length);
    final index = incoming[incoming.length - visibleUnread];
    final out = [...items];
    out.insert(index, {
      'kind': kind,
      'count': unreadCount,
      'label': bannerLabel(unreadCount),
    });
    return out;
  }

  static bool _isIncomingMessage(Map<String, dynamic> item) {
    if (isStructuralKind(item['kind']?.toString())) return false;
    if (item['is_sent'] == true) return false;
    return true;
  }
}
