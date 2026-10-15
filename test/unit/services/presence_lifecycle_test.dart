import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/services/presence_lifecycle.dart';
import 'package:lgbtindernew/core/services/presence_service.dart';
import 'package:lgbtindernew/features/chat/utils/presence_freshness.dart';

void main() {
  test('paused, hidden, and detached mark the user offline', () {
    expect(
      presenceSignalForLifecycle(AppLifecycleState.paused),
      PresenceLifecycleSignal.offline,
    );
    expect(
      presenceSignalForLifecycle(AppLifecycleState.hidden),
      PresenceLifecycleSignal.offline,
    );
    expect(
      presenceSignalForLifecycle(AppLifecycleState.detached),
      PresenceLifecycleSignal.offline,
    );
  });

  test('resumed marks the user online and inactive does not flip presence', () {
    expect(
      presenceSignalForLifecycle(AppLifecycleState.resumed),
      PresenceLifecycleSignal.online,
    );
    expect(
      presenceSignalForLifecycle(AppLifecycleState.inactive),
      PresenceLifecycleSignal.none,
    );
  });

  test('foreground heartbeat stays between 30 and 60 seconds and inside the TTL', () {
    expect(PresenceService.heartbeatInterval.inSeconds, greaterThanOrEqualTo(30));
    expect(PresenceService.heartbeatInterval.inSeconds, lessThanOrEqualTo(60));
    expect(PresenceService.heartbeatInterval < PresenceFreshness.ttl, isTrue);
    expect(PresenceService.statusDebounce, const Duration(seconds: 2));
  });

  test('online stays until an offline presence event', () {
    final now = DateTime(2026, 10, 15, 19, 2, 0);
    expect(
      PresenceFreshness.isEffectivelyOnline(
        isOnline: true,
        refreshedAt: DateTime(2026, 10, 15, 19, 0, 0),
        now: now,
      ),
      isTrue,
    );
    expect(
      PresenceFreshness.isEffectivelyOnline(
        isOnline: false,
        refreshedAt: now,
        now: now,
      ),
      isFalse,
    );
  });

  test('lifecycle flaps within 2 seconds emit only the latest signal', () {
    final emitted = <bool>[];
    final debouncer = PresenceChangeDebouncer(
      window: const Duration(seconds: 2),
    );
    addTearDown(debouncer.dispose);

    fakeAsync((async) {
      debouncer.schedule(false, emitted.add);
      async.elapse(const Duration(milliseconds: 500));
      debouncer.schedule(true, emitted.add);
      async.elapse(const Duration(seconds: 2));
      expect(emitted, [true]);
    });
  });
}
