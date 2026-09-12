import '../data/models/message.dart';
import 'chat_message_dedup.dart';
import 'chat_thread_row_map.dart';
import 'chat_timeline_merger.dart';
import 'chat_timeline_slots.dart';

/// Builds thread rows from Drift snapshots without dropping in-flight UI rows.
class ChatThreadLocalApply {
  ChatThreadLocalApply._();

  static List<Map<String, dynamic>> combine({
    required List<Message> messages,
    required int peerUserId,
    int? currentUserId,
    required List<Map<String, dynamic>> callRows,
    required List<Map<String, dynamic>> previousRows,
    String? Function(int? replyToId)? replyPreview,
  }) {
    final previousById = <int, Map<String, dynamic>>{
      for (final row in previousRows)
        if (_numericId(row['id']) > 0) _numericId(row['id']): row,
    };
    final mapped = [
      for (final message in messages)
        _overlayMonotonicFlags(
          ChatThreadRowMap.fromMessage(
            message,
            peerUserId: peerUserId,
            currentUserId: currentUserId,
            replyPreview: replyPreview,
          ),
          previousById[_numericId(message.id)],
        ),
    ];
    final merged = ChatTimelineMerger.merge(
      messages: mapped,
      calls: _dedupeCalls([...callRows, ..._callRows(previousRows)]),
    );
    final withOptimistic = ChatTimelineMerger.withInFlightOptimistic(
      serverTimeline: merged,
      previous: previousRows,
    );
    final snapshotIds = <int>{
      for (final row in withOptimistic)
        if (_numericId(row['id']) > 0) _numericId(row['id']),
    };
    final pending = [
      for (final row in previousRows)
        if (_keepPending(row, snapshotIds)) row,
    ];
    if (pending.isEmpty) return withOptimistic;
    return ChatTimelineMerger.sortChronologically(
      ChatMessageDedup.fold([...withOptimistic, ...pending]),
    );
  }

  static bool sameSnapshot(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (fingerprint(a[i]) != fingerprint(b[i])) return false;
    }
    return true;
  }

  static String fingerprint(Map<String, dynamic> row) {
    return [
      ChatTimelineSlots.rowKey(row),
      row['text'],
      row['is_sent'],
      row['is_read'],
      row['is_delivered'],
      row['is_edited'],
      row['is_deleted'],
      row['delivery_status'],
      row['remaining_seconds'],
      row['is_expired'],
      row['my_reaction'],
      row['reactions'],
    ].join('|');
  }

  /// Keep live receipt / expire / delete flags if Drift has not persisted yet.
  static Map<String, dynamic> _overlayMonotonicFlags(
    Map<String, dynamic> dbRow,
    Map<String, dynamic>? live,
  ) {
    if (live == null) return dbRow;
    return {
      ...dbRow,
      if (live['is_read'] == true) 'is_read': true,
      if (live['is_delivered'] == true) 'is_delivered': true,
      if (live['is_expired'] == true) 'is_expired': true,
      if (live['is_deleted'] == true) 'is_deleted': true,
      if (live['is_edited'] == true) 'is_edited': true,
      if (live['edited_at'] != null) 'edited_at': live['edited_at'],
    };
  }

  static bool _keepPending(Map<String, dynamic> row, Set<int> snapshotIds) {
    final kind = row['kind']?.toString();
    if (kind == 'call' || kind == 'date_badge' || kind == 'unread_separator') {
      return false;
    }
    final id = _numericId(row['id']);
    if (id > 0 && !snapshotIds.contains(id)) return true;
    return false;
  }

  static List<Map<String, dynamic>> _callRows(
    List<Map<String, dynamic>> rows,
  ) {
    return [for (final row in rows) if (row['kind'] == 'call') row];
  }

  static List<Map<String, dynamic>> _dedupeCalls(
    List<Map<String, dynamic>> rows,
  ) {
    final seen = <int>{};
    final out = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = _numericId(row['call_id'] ?? row['id']);
      if (id > 0 && !seen.add(id)) continue;
      out.add(row);
    }
    return out;
  }

  static int _numericId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
