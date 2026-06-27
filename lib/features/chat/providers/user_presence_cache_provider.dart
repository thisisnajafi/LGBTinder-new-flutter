import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/pusher_websocket_service.dart';

/// Cached online / last-seen snapshot for a user (updated via Pusher).
class UserPresenceSnapshot {
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime updatedAt;

  const UserPresenceSnapshot({
    required this.isOnline,
    this.lastSeenAt,
    required this.updatedAt,
  });
}

final userPresenceCacheProvider =
    NotifierProvider<UserPresenceCacheNotifier, Map<int, UserPresenceSnapshot>>(
  UserPresenceCacheNotifier.new,
);

class UserPresenceCacheNotifier extends Notifier<Map<int, UserPresenceSnapshot>> {
  @override
  Map<int, UserPresenceSnapshot> build() => {};

  void apply(UserPresenceEvent event) {
    state = {
      ...state,
      event.userId: UserPresenceSnapshot(
        isOnline: event.isOnline,
        lastSeenAt: event.lastSeenAt,
        updatedAt: event.timestamp,
      ),
    };
  }
}
