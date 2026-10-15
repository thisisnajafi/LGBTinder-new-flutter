import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/chat/providers/user_presence_cache_provider.dart';
import 'package:lgbtindernew/shared/services/pusher_websocket_service.dart';

void main() {
  group('UserPresenceCacheNotifier', () {
    test('apply stores online snapshot by user id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userPresenceCacheProvider.notifier);
      final event = UserPresenceEvent(
        userId: 42,
        isOnline: true,
        lastSeenAt: DateTime.parse('2026-06-26T12:00:00Z'),
        timestamp: DateTime.parse('2026-06-26T12:00:01Z'),
      );

      notifier.apply(event);

      final snapshot = container.read(userPresenceCacheProvider)[42];
      expect(snapshot, isNotNull);
      expect(snapshot!.isOnline, isTrue);
      expect(snapshot.lastSeenAt, event.lastSeenAt);
    });

    test('apply ignores duplicate snapshots', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userPresenceCacheProvider.notifier);
      final seen = DateTime.parse('2026-06-26T12:00:00Z');
      notifier.apply(
        UserPresenceEvent(
          userId: 42,
          isOnline: true,
          lastSeenAt: seen,
          timestamp: DateTime.parse('2026-06-26T12:00:01Z'),
        ),
      );
      final first = container.read(userPresenceCacheProvider);

      notifier.apply(
        UserPresenceEvent(
          userId: 42,
          isOnline: true,
          lastSeenAt: seen,
          timestamp: DateTime.parse('2026-06-26T12:00:02Z'),
        ),
      );

      expect(
        identical(container.read(userPresenceCacheProvider), first),
        isTrue,
      );
    });

    test('apply ignores a newer last seen while online state is unchanged', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userPresenceCacheProvider.notifier);
      notifier.apply(
        UserPresenceEvent(
          userId: 42,
          isOnline: true,
          lastSeenAt: DateTime.parse('2026-06-26T12:00:00Z'),
          timestamp: DateTime.parse('2026-06-26T12:00:01Z'),
        ),
      );
      final first = container.read(userPresenceCacheProvider);

      notifier.apply(
        UserPresenceEvent(
          userId: 42,
          isOnline: true,
          lastSeenAt: DateTime.parse('2026-06-26T12:00:30Z'),
          timestamp: DateTime.parse('2026-06-26T12:00:31Z'),
        ),
      );

      expect(identical(container.read(userPresenceCacheProvider), first), isTrue);

      notifier.apply(
        UserPresenceEvent(
          userId: 42,
          isOnline: false,
          lastSeenAt: DateTime.parse('2026-06-26T12:00:30Z'),
          timestamp: DateTime.parse('2026-06-26T12:00:40Z'),
        ),
      );
      expect(container.read(userPresenceCacheProvider)[42]!.isOnline, isFalse);
      expect(
        container.read(userPresenceCacheProvider)[42]!.lastSeenAt,
        DateTime.parse('2026-06-26T12:00:30Z'),
      );
    });
  });
}
