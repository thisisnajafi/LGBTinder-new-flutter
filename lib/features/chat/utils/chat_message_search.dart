/// One conversation row produced from message-search hits (PERF-FEAT-CHAT-004).
class ChatMessageSearchHit {
  const ChatMessageSearchHit({
    required this.otherUserId,
    required this.name,
    required this.preview,
    required this.createdAt,
    this.avatarUrl,
  });

  final int otherUserId;
  final String name;
  final String preview;
  final DateTime createdAt;
  final String? avatarUrl;

  Map<String, dynamic> toListRow() {
    return {
      'id': otherUserId,
      'name': name,
      'avatar_url': avatarUrl,
      'last_message': preview,
      'last_message_time': createdAt,
      'unread_count': 0,
      'is_online': false,
    };
  }
}

String escapeChatSearchLike(String query) {
  return query
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

bool messageSearchPageHasMore(int pageLength, {int pageSize = 20}) {
  return pageLength >= pageSize;
}

/// Keeps the newest hit per peer, newest conversations first.
List<ChatMessageSearchHit> groupMessageSearchHits(
  Iterable<ChatMessageSearchHit> hits,
) {
  final byUser = <int, ChatMessageSearchHit>{};
  for (final hit in hits) {
    if (hit.otherUserId <= 0) continue;
    final existing = byUser[hit.otherUserId];
    if (existing == null || hit.createdAt.isAfter(existing.createdAt)) {
      byUser[hit.otherUserId] = hit;
    }
  }
  final grouped = byUser.values.toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return grouped;
}

ChatMessageSearchHit? chatMessageSearchHitFromApi(Map<String, dynamic> json) {
  final otherUser = json['other_user'];
  if (otherUser is! Map) return null;
  final user = Map<String, dynamic>.from(otherUser);
  final idRaw = user['id'];
  final otherUserId = idRaw is int
      ? idRaw
      : int.tryParse(idRaw?.toString() ?? '') ?? 0;
  if (otherUserId <= 0) return null;

  final createdRaw = json['created_at'];
  DateTime createdAt;
  if (createdRaw is DateTime) {
    createdAt = createdRaw.toLocal();
  } else {
    createdAt = DateTime.tryParse(createdRaw?.toString() ?? '')?.toLocal() ??
        DateTime.now();
  }

  final name = user['name']?.toString().trim();
  return ChatMessageSearchHit(
    otherUserId: otherUserId,
    name: (name == null || name.isEmpty) ? 'User' : name,
    avatarUrl: user['avatar_url']?.toString(),
    preview: json['message']?.toString() ?? '',
    createdAt: createdAt,
  );
}
