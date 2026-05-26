/// Merge chat messages and call log entries into a single chronological timeline.
class ChatTimelineMerger {
  ChatTimelineMerger._();

  static List<Map<String, dynamic>> merge({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> calls,
  }) {
    final merged = <Map<String, dynamic>>[
      ...messages.map((m) => {...m, 'kind': 'message'}),
      ...calls.map((c) => {...c, 'kind': 'call'}),
    ];

    merged.sort((a, b) {
      final ta = a['timestamp'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b['timestamp'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ta.compareTo(tb);
    });

    final seenCallIds = <int>{};
    return merged.where((item) {
      if (item['kind'] != 'call') return true;
      final id = item['call_id'];
      final parsed = id is int ? id : int.tryParse(id?.toString() ?? '');
      if (parsed == null || parsed <= 0) return true;
      if (seenCallIds.contains(parsed)) return false;
      seenCallIds.add(parsed);
      return true;
    }).toList();
  }
}
