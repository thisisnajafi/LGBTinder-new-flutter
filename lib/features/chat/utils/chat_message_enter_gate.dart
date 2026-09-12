/// Decides whether a chat row should play its enter animation
/// (CHAT-THREAD-001 send, CHAT-THREAD-002 receive).
///
/// History and pagination must [markAll] before the first build so old
/// bubbles do not stagger in. A new optimistic send or Pusher receive is
/// unseen → [takeNew] returns true once per identity.
class ChatMessageEnterGate {
  ChatMessageEnterGate();

  final Set<String> _seen = {};

  int get seenCount => _seen.length;

  static String? identity({
    String? clientId,
    dynamic id,
    String? kind,
  }) {
    if (kind == 'call' ||
        kind == 'date_badge' ||
        kind == 'unread_separator') {
      return null;
    }
    final client = clientId?.trim() ?? '';
    if (client.isNotEmpty) return 'c:$client';
    final raw = id?.toString() ?? '';
    if (raw.isNotEmpty && raw != '0') return 'i:$raw';
    return null;
  }

  static String? identityOf(Map<String, dynamic> item) {
    return identity(
      clientId: item['client_id']?.toString(),
      id: item['id'],
      kind: item['kind']?.toString(),
    );
  }

  void markIdentity(String? key) {
    if (key == null || key.isEmpty) return;
    _seen.add(key);
  }

  void markAll(Iterable<Map<String, dynamic>> items) {
    for (final item in items) {
      markIdentity(identityOf(item));
    }
  }

  bool hasSeen(String? key) => key != null && _seen.contains(key);

  /// First unseen row (sent or received) animates. Repeats do not.
  bool takeNew(Map<String, dynamic> message) {
    final key = identityOf(message);
    if (key == null) return false;
    if (_seen.contains(key)) return false;
    _seen.add(key);
    return true;
  }
}
