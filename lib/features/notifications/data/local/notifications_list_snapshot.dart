import '../models/notification.dart' as app_models;

const int kNotificationsPageSize = 20;

/// Drops chat-message rows — those belong in the chat list, not this feed.
List<app_models.Notification> withoutChatMessageNotifications(
  List<app_models.Notification> items,
) {
  return items
      .where((n) => n.type.toLowerCase() != 'message')
      .toList(growable: false);
}

class NotificationsLocalSnapshot {
  const NotificationsLocalSnapshot({
    required this.notifications,
    this.currentPage = 1,
    this.hasMore = true,
    this.unreadCount,
  });

  final List<app_models.Notification> notifications;
  final int currentPage;
  final bool hasMore;
  final int? unreadCount;

  static NotificationsLocalSnapshot? fromCacheMap(Map<String, dynamic> cached) {
    final rawList = cached['notifications'];
    if (rawList is! List || rawList.isEmpty) return null;

    final notifications = <app_models.Notification>[];
    for (final item in rawList) {
      if (item is! Map) continue;
      try {
        notifications.add(
          app_models.Notification.fromJson(Map<String, dynamic>.from(item)),
        );
      } catch (_) {
        continue;
      }
    }
    if (notifications.isEmpty) return null;

    final filtered = withoutChatMessageNotifications(notifications);
    if (filtered.isEmpty) return null;

    final currentPage = cached['current_page'] is int
        ? cached['current_page'] as int
        : (cached['current_page'] is num
            ? (cached['current_page'] as num).toInt()
            : 2);
    final hasMore = cached['has_more'] is bool
        ? cached['has_more'] as bool
        : filtered.length >= kNotificationsPageSize;
    final unread = cached['unread_count'];
    final unreadCount = unread is int
        ? unread
        : unread is num
            ? unread.toInt()
            : null;

    return NotificationsLocalSnapshot(
      notifications: filtered,
      currentPage: currentPage,
      hasMore: hasMore,
      unreadCount: unreadCount,
    );
  }
}
