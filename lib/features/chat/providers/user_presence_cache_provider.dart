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
    if (event.userId <= 0) return;
    final next = UserPresenceSnapshot(
      isOnline: event.isOnline,
      lastSeenAt: event.lastSeenAt,
      updatedAt: event.timestamp,
    );
    final previous = state[event.userId];
    if (previous != null &&
        previous.isOnline == next.isOnline &&
        previous.lastSeenAt == next.lastSeenAt) {
      return;
    }
    state = {
      ...state,
      event.userId: next,
    };
  }
}
