import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/notifications/data/foreground_push_policy.dart';

void main() {
  test('device notifications are off while the app is in the foreground', () {
    expect(
      ForegroundPushPolicy.shouldShowDeviceNotification(
        appForeground: true,
        isIncomingCall: false,
      ),
      isFalse,
    );
  });

  test('device notifications are on when the app is backgrounded', () {
    expect(
      ForegroundPushPolicy.shouldShowDeviceNotification(
        appForeground: false,
        isIncomingCall: false,
      ),
      isTrue,
    );
  });

  test('incoming calls never use a device tray notification', () {
    expect(
      ForegroundPushPolicy.shouldShowDeviceNotification(
        appForeground: false,
        isIncomingCall: true,
      ),
      isFalse,
    );
  });
}
