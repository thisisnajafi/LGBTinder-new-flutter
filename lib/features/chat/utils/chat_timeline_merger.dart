/// Merge chat messages and call log entries into a single chronological timeline.
class ChatTimelineMerger {
  ChatTimelineMerger._();

  static List<Map<String, dynamic>> merge({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> calls,
  }) {
    final merged = <Map<String, dynamic>>[
      ...messages.map((m) => {...m, 'kind': m['kind'] ?? 'message'}),
      ...calls.map((c) => {...c, 'kind': 'call'}),
    ];

    final seenCallIds = <int>{};
    final deduped = merged.where((item) {
      if (item['kind'] != 'call') return true;
      final parsed = _numericId(item['call_id']);
      if (parsed <= 0) return true;
      if (seenCallIds.contains(parsed)) return false;
      seenCallIds.add(parsed);
      return true;
    }).toList();

    return sortChronologically(deduped);
  }

  /// Oldest → newest. Same-second messages use server id so rapid sends stay in order.
  static List<Map<String, dynamic>> sortChronologically(
    List<Map<String, dynamic>> items,
  ) {
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort(compareChronologically);
    return sorted;
  }

  static int compareChronologically(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final byTime = _timestamp(a).compareTo(_timestamp(b));
    if (byTime != 0) return byTime;

    final ida = _sortId(a);
    final idb = _sortId(b);
    // Optimistic / local rows (id 0) stay after persisted rows at the same instant.
    if (ida <= 0 && idb > 0) return 1;
    if (idb <= 0 && ida > 0) return -1;
    return ida.compareTo(idb);
  }

  static DateTime _timestamp(Map<String, dynamic> item) {
    final raw = item['timestamp'];
    if (raw is DateTime) return raw;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int _sortId(Map<String, dynamic> item) {
    if (item['kind'] == 'call') {
      return _numericId(item['call_id']);
    }
    return _numericId(item['id']);
  }

  static int _numericId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
