import '../data/models/message.dart';
import 'chat_optimistic.dart';

/// Result of inserting or replacing a typed [Message] in a list.
class ChatMessageUpsert {
  const ChatMessageUpsert({
    required this.messages,
    required this.insertedNew,
    required this.index,
  });

  final List<Message> messages;
  final bool insertedNew;
  final int index;
}

/// Collapse send + echo into one row: server `id` first, then `client_id`.
class ChatMessageDedup {
  ChatMessageDedup._();

  /// Index of [incoming] in [messages]. Persisted id wins over `client_id`.
  static int indexOfMessage(List<Message> messages, Message incoming) {
    if (incoming.id > 0) {
      final at = messages.indexWhere((m) => m.id == incoming.id);
      if (at >= 0) return at;
    }
    if (!ChatOptimistic.hasClientId(incoming.clientId)) return -1;
    return messages.indexWhere(
      (m) => ChatOptimistic.isClientIdMatch(m.clientId, incoming.clientId),
    );
  }

  /// Update in place when the row exists; otherwise prepend.
  static ChatMessageUpsert upsertMessage(
    List<Message> current,
    Message incoming,
  ) {
    final at = indexOfMessage(current, incoming);
    if (at >= 0) {
      final next = List<Message>.from(current);
      next[at] = incoming;
      return ChatMessageUpsert(
        messages: next,
        insertedNew: false,
        index: at,
      );
    }
    return ChatMessageUpsert(
      messages: [incoming, ...current],
      insertedNew: true,
      index: 0,
    );
  }

  /// Linear scan used when the O(1) thread index is stale. No text/time match.
  static int indexOfRow(
    List<Map<String, dynamic>> rows, {
    int serverId = 0,
    String? clientId,
  }) {
    if (serverId > 0) {
      for (var i = 0; i < rows.length; i++) {
        if (rows[i]['kind'] == 'call') continue;
        if (ChatOptimistic.sameMessageId(rows[i]['id'], serverId)) return i;
      }
    }
    if (!ChatOptimistic.hasClientId(clientId)) return -1;
    for (var i = 0; i < rows.length; i++) {
      if (ChatOptimistic.isClientIdMatch(
        rows[i]['client_id']?.toString(),
        clientId,
      )) {
        return i;
      }
    }
    return -1;
  }

  /// Collapse duplicate messages (`id` / `client_id`) and calls (`call_id`).
  /// Later persisted rows win; a local optimistic row never overwrites a server id.
  static List<Map<String, dynamic>> fold(List<Map<String, dynamic>> items) {
    final byServer = <int, int>{};
    final byClient = <String, int>{};
    final byCall = <int, int>{};
    final out = <Map<String, dynamic>>[];

    void rememberMessage(int i, Map<String, dynamic> row) {
      final id = ChatOptimistic.parseMessageId(row['id']);
      if (id > 0) byServer[id] = i;
      final client = row['client_id']?.toString();
      if (client != null && ChatOptimistic.hasClientId(client)) {
        byClient[client] = i;
      }
    }

    void forgetMessage(int i, Map<String, dynamic> row) {
      final id = ChatOptimistic.parseMessageId(row['id']);
      if (id > 0 && byServer[id] == i) byServer.remove(id);
      final client = row['client_id']?.toString();
      if (client != null &&
          ChatOptimistic.hasClientId(client) &&
          byClient[client] == i) {
        byClient.remove(client);
      }
    }

    for (final item in items) {
      if (item['kind'] == 'call') {
        final callId = ChatOptimistic.parseMessageId(item['call_id']);
        if (callId > 0) {
          final at = byCall[callId];
          if (at != null) {
            out[at] = {...out[at], ...item};
            continue;
          }
          byCall[callId] = out.length;
        }
        out.add(item);
        continue;
      }

      final id = ChatOptimistic.parseMessageId(item['id']);
      final client = item['client_id']?.toString();
      int? at;
      if (id > 0) at = byServer[id];
      if (at == null &&
          client != null &&
          ChatOptimistic.hasClientId(client)) {
        at = byClient[client];
      }
      if (at != null) {
        forgetMessage(at, out[at]);
        final merged = mergeMaps(out[at], item);
        out[at] = merged;
        rememberMessage(at, merged);
      } else {
        out.add(item);
        rememberMessage(out.length - 1, item);
      }
    }
    return out;
  }

  /// Prefer the persisted server row when an optimistic copy arrives later.
  static Map<String, dynamic> mergeMaps(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) {
    final existingId = ChatOptimistic.parseMessageId(existing['id']);
    final incomingId = ChatOptimistic.parseMessageId(incoming['id']);
    if (existingId > 0 && incomingId <= 0) {
      final existingClient = existing['client_id']?.toString();
      final incomingClient = incoming['client_id']?.toString();
      return {
        ...incoming,
        ...existing,
        if (!ChatOptimistic.hasClientId(existingClient) &&
            ChatOptimistic.hasClientId(incomingClient))
          'client_id': incoming['client_id'],
      };
    }
    return {...existing, ...incoming};
  }
}
