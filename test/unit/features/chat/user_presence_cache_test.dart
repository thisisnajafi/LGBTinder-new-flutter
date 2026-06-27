import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/providers/user_presence_cache_provider.dart';
import 'package:lgbtindernew/shared/services/pusher_websocket_service.dart';

void main() {
  group('UserPresenceCacheNotifier', () {
    test('apply stores online snapshot by user id', () {
      final notifier = UserPresenceCacheNotifier();
      final event = UserPresenceEvent(
        userId: 42,
        isOnline: true,
        lastSeenAt: DateTime.parse('2026-06-26T12:00:00Z'),
        timestamp: DateTime.parse('2026-06-26T12:00:01Z'),
      );

      notifier.apply(event);

      final snapshot = notifier.state[42];
      expect(snapshot, isNotNull);
      expect(snapshot!.isOnline, isTrue);
      expect(snapshot.lastSeenAt, event.lastSeenAt);
    });
  });
}
