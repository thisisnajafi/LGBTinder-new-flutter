/// Reconcile an optimistic bubble with the server/Pusher copy (CHAT-RT-001).
class ChatOptimistic {
  ChatOptimistic._();

  static bool hasClientId(String? id) => id != null && id.isNotEmpty;

  static bool isClientIdMatch(String? localId, String? remoteId) {
    return hasClientId(localId) && hasClientId(remoteId) && localId == remoteId;
  }

  static int parseMessageId(dynamic rawId) {
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  static bool sameMessageId(dynamic rawId, int messageId) {
    if (messageId <= 0) return false;
    return parseMessageId(rawId) == messageId;
  }

  /// Keep the server row if Pusher already applied it; otherwise swap the temp row.
  static List<Map<String, dynamic>> replaceWithServer({
    required List<Map<String, dynamic>> messages,
    required String clientId,
    required int serverId,
    required Map<String, dynamic> serverMap,
  }) {
    var hasServer = false;
    final kept = <Map<String, dynamic>>[];
    for (final row in messages) {
      if (sameMessageId(row['id'], serverId)) {
        kept.add(row);
        hasServer = true;
        continue;
      }
      if (row['client_id']?.toString() == clientId) continue;
      kept.add(row);
    }
    if (!hasServer) kept.add(serverMap);
    return kept;
  }
}
