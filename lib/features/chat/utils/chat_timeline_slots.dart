import '../../calls/data/models/call.dart';

/// Structural slots for the reverse chat list (CHAT-PERF-003).
///
/// Equality ignores message body so a delivery/edit patch does not rebuild
/// the [ListView] parent — only the tile that `select`s that row.
enum ChatTimelineSlotKind { date, unread, call, message, upgradeOlder }

class ChatTimelineSlot {
  final ChatTimelineSlotKind kind;
  final String key;
  final String? label;
  final int unreadCount;
  /// Outgoing vs incoming for message slots (CHAT-BUBBLE-001 grouping).
  final bool? isSent;

  const ChatTimelineSlot({
    required this.kind,
    required this.key,
    this.label,
    this.unreadCount = 0,
    this.isSent,
  });

  @override
  bool operator ==(Object other) {
    return other is ChatTimelineSlot &&
        other.kind == kind &&
        other.key == key &&
        other.label == label &&
        other.unreadCount == unreadCount &&
        other.isSent == isSent;
  }

  @override
  int get hashCode => Object.hash(kind, key, label, unreadCount, isSent);
}

class ChatTimelineSlots {
  ChatTimelineSlots._();

  static String rowKey(Map<String, dynamic> row, {int fallbackIndex = 0}) {
    final kind = row['kind']?.toString();
    if (kind == 'call') {
      final call = row['call'];
      final id = call is Call ? call.id : row['call_id'] ?? row['id'];
      return 'call-$id';
    }
    if (kind == 'date_badge') {
      return 'date-${row['label']}-${row['timestamp']}';
    }
    if (kind == 'unread_separator') {
      return 'unread';
    }
    final clientId = row['client_id']?.toString();
    if (clientId != null && clientId.isNotEmpty) return 'c-$clientId';
    final id = row['id'];
    if (id != null && id.toString().isNotEmpty && id.toString() != '0') {
      return 'id-$id';
    }
    return 'idx-$fallbackIndex';
  }

  static Map<String, dynamic>? findRow(
    List<Map<String, dynamic>> rows,
    String key,
  ) {
    for (final row in rows) {
      if (rowKey(row) == key) return row;
    }
    return null;
  }

  static const String upgradeOlderKey = 'upgrade-older-messages';

  /// Drops blurred history rows. [collapsed] is true when at least one was removed.
  static ({List<Map<String, dynamic>> rows, bool collapsed}) droppingBlurred(
    List<Map<String, dynamic>> rows,
  ) {
    var collapsed = false;
    final kept = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row['is_blurred'] == true) {
        collapsed = true;
        continue;
      }
      kept.add(row);
    }
    return (rows: collapsed ? kept : rows, collapsed: collapsed);
  }

  static List<ChatTimelineSlot> build({
    required List<Map<String, dynamic>> decoratedRows,
    bool prependOlderUpgrade = false,
  }) {
    final slots = [
      for (var i = 0; i < decoratedRows.length; i++)
        _slotOf(decoratedRows[i], i),
    ];
    if (!prependOlderUpgrade) return slots;
    return [
      const ChatTimelineSlot(
        kind: ChatTimelineSlotKind.upgradeOlder,
        key: upgradeOlderKey,
      ),
      ...slots,
    ];
  }

  static ChatTimelineSlot _slotOf(Map<String, dynamic> row, int index) {
    final kind = row['kind']?.toString();
    if (kind == 'date_badge') {
      return ChatTimelineSlot(
        kind: ChatTimelineSlotKind.date,
        key: rowKey(row, fallbackIndex: index),
        label: row['label']?.toString() ?? '',
      );
    }
    if (kind == 'unread_separator') {
      return ChatTimelineSlot(
        kind: ChatTimelineSlotKind.unread,
        key: 'unread',
        unreadCount: row['count'] is int ? row['count'] as int : 0,
      );
    }
    if (kind == 'call') {
      return ChatTimelineSlot(
        kind: ChatTimelineSlotKind.call,
        key: rowKey(row, fallbackIndex: index),
      );
    }
    return ChatTimelineSlot(
      kind: ChatTimelineSlotKind.message,
      key: rowKey(row, fallbackIndex: index),
      isSent: row['is_sent'] == true,
    );
  }
}
