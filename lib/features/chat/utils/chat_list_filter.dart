/// One-pass messenger list filter (CHAT-PERF-009).
enum ChatListRowFilter { all, unread, online }

abstract final class ChatListFilter {
  /// Filter + search in a single walk of [source].
  static List<Map<String, dynamic>> apply({
    required List<Map<String, dynamic>> source,
    required ChatListRowFilter filter,
    String query = '',
    Set<int> hiddenIds = const {},
    Map<int, bool> presenceByUser = const {},
  }) {
    final needle = query.trim().toLowerCase();
    final out = <Map<String, dynamic>>[];
    for (final chat in source) {
      final id = chat['id'] as int? ?? 0;
      if (hiddenIds.contains(id)) continue;
      if (!_matchesFilter(chat, filter, presenceByUser: presenceByUser)) {
        continue;
      }
      if (needle.isNotEmpty && !_matchesQuery(chat, needle)) continue;
      out.add(chat);
    }
    if (out.isEmpty) return out;
    final pinned = <Map<String, dynamic>>[];
    final rest = <Map<String, dynamic>>[];
    for (final chat in out) {
      if (_isPinned(chat)) {
        pinned.add(chat);
      } else {
        rest.add(chat);
      }
    }
    return [...pinned, ...rest];
  }

  static bool _isPinned(Map<String, dynamic> chat) =>
      chat['is_pinned'] == true || chat['is_pinned'] == 1;

  static bool _matchesFilter(
    Map<String, dynamic> chat,
    ChatListRowFilter filter, {
    Map<int, bool> presenceByUser = const {},
  }) {
    switch (filter) {
      case ChatListRowFilter.unread:
        return (chat['unread_count'] as int? ?? 0) > 0;
      case ChatListRowFilter.online:
        final id = chat['id'] as int? ?? 0;
        final live = presenceByUser[id];
        if (live != null) return live;
        return chat['is_online'] == true || chat['is_online'] == 1;
      case ChatListRowFilter.all:
        return true;
    }
  }

  static bool _matchesQuery(Map<String, dynamic> chat, String needle) {
    bool has(dynamic raw) =>
        (raw?.toString().toLowerCase() ?? '').contains(needle);
    if (has(chat['name'])) return true;
    if (has(chat['first_name'])) return true;
    if (has(chat['last_name'])) return true;
    return has(chat['last_message']);
  }
}
