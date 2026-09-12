import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/shared/services/call_token_refresh.dart';

void main() {
  group('CallTokenRefresh.delayUntilRefresh', () {
    final now = DateTime.utc(2026, 9, 11, 12, 0, 0);

    test('schedules 5 minutes before a 1-hour token', () {
      final expiresAt = now.add(const Duration(hours: 1));
      expect(
        CallTokenRefresh.delayUntilRefresh(expiresAt, now),
        const Duration(minutes: 55),
      );
    });

    test('refreshes immediately when already inside the lead window', () {
      final expiresAt = now.add(const Duration(minutes: 3));
      expect(
        CallTokenRefresh.delayUntilRefresh(expiresAt, now),
        Duration.zero,
      );
    });

    test('refreshes immediately when expiresAt is in the past', () {
      final expiresAt = now.subtract(const Duration(minutes: 1));
      expect(
        CallTokenRefresh.delayUntilRefresh(expiresAt, now),
        Duration.zero,
      );
    });

    test('refreshes immediately when expiry is exactly the lead time away', () {
      final expiresAt = now.add(CallTokenRefresh.leadTime);
      expect(
        CallTokenRefresh.delayUntilRefresh(expiresAt, now),
        Duration.zero,
      );
    });
  });

  test('empty refresh result is not treated as a token', () {
    expect(const CallTokenRefreshResult(token: '').hasToken, isFalse);
    expect(
      const CallTokenRefreshResult(token: 'abc', expiresAt: null).hasToken,
      isTrue,
    );
  });
}
