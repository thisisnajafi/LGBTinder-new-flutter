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

  test('foreground heartbeat interval stays inside the presence TTL', () {
    expect(
      PresenceService.heartbeatInterval < PresenceFreshness.ttl,
      isTrue,
    );
  });

  test('online presence expires after the TTL without a new heartbeat', () {
    final now = DateTime(2026, 10, 15, 19, 0, 25);
    expect(
      PresenceFreshness.isEffectivelyOnline(
        isOnline: true,
        refreshedAt: DateTime(2026, 10, 15, 19, 0, 0),
        now: now,
      ),
      isFalse,
    );
    expect(
      PresenceFreshness.isEffectivelyOnline(
        isOnline: true,
        refreshedAt: DateTime(2026, 10, 15, 19, 0, 10),
        now: now,
      ),
      isTrue,
    );
    expect(
      PresenceFreshness.isEffectivelyOnline(
        isOnline: false,
        refreshedAt: DateTime(2026, 10, 15, 19, 0, 24),
        now: now,
      ),
      isFalse,
    );
  });
}
