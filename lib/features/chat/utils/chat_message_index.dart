import 'chat_optimistic.dart';

/// O(1) lookup of thread rows by server id and `client_id` (CHAT-PERF-004).
class ChatMessageIndex {
  ChatMessageIndex();

  final Map<int, int> _byServerId = <int, int>{};
  final Map<String, int> _byClientId = <String, int>{};

  int get serverIdCount => _byServerId.length;

  int get clientIdCount => _byClientId.length;

  void clear() {
    _byServerId.clear();
    _byClientId.clear();
  }

  void rebuild(List<Map<String, dynamic>> messages) {
    clear();
    for (var i = 0; i < messages.length; i++) {
      _index(messages[i], i);
    }
  }

  int? byServerId(dynamic rawId) {
    final id = ChatOptimistic.parseMessageId(rawId);
    if (id <= 0) return null;
    return _byServerId[id];
  }

  int? byClientId(String? clientId) {
    if (clientId == null || clientId.isEmpty) return null;
    return _byClientId[clientId];
  }

  /// Replace one row and keep maps aligned without a full rebuild.
  void replaceAt(
    List<Map<String, dynamic>> messages,
    int index,
    Map<String, dynamic> next,
  ) {
    if (index < 0 || index >= messages.length) return;
    _unindex(messages[index], index);
    messages[index] = next;
    _index(next, index);
  }

  void _index(Map<String, dynamic> row, int index) {
    if (row['kind'] == 'call') return;
    final id = ChatOptimistic.parseMessageId(row['id']);
    if (id > 0) _byServerId[id] = index;
    final clientId = row['client_id']?.toString();
    if (clientId != null && clientId.isNotEmpty) {
      _byClientId[clientId] = index;
    }
  }

  void _unindex(Map<String, dynamic> row, int index) {
    if (row['kind'] == 'call') return;
    final id = ChatOptimistic.parseMessageId(row['id']);
    if (id > 0 && _byServerId[id] == index) {
      _byServerId.remove(id);
    }
    final clientId = row['client_id']?.toString();
    if (clientId != null &&
        clientId.isNotEmpty &&
        _byClientId[clientId] == index) {
      _byClientId.remove(clientId);
    }
  }
}
