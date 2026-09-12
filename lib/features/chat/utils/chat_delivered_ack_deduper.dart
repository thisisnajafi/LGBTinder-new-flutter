/// Prevents repeat `POST /chat/delivered` for ids already acked (CHAT-RT-005).
class ChatDeliveredAckDeduper {
  final Set<int> _acked = <int>{};

  List<int> take(Iterable<int> ids) {
    final fresh = <int>[];
    for (final id in ids) {
      if (id <= 0 || !_acked.add(id)) continue;
      fresh.add(id);
    }
    return fresh;
  }

  void release(Iterable<int> ids) {
    _acked.removeAll(ids);
  }

  bool contains(int id) => _acked.contains(id);
}
