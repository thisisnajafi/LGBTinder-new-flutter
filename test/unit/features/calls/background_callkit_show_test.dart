import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/utils/background_callkit_show.dart';

void main() {
  group('BackgroundCallKitShow', () {
    test('a background or killed incoming call shows CallKit', () {
      expect(
        BackgroundCallKitShow.shouldShow(
          callId: '79',
          terminalCallIds: const {},
          permissionRequestInFlight: false,
        ),
        isTrue,
      );
    });

    test('a decline stored for another call does not hide the next one', () {
      expect(
        BackgroundCallKitShow.shouldShow(
          callId: '79',
          terminalCallIds: const {'77'},
          permissionRequestInFlight: false,
        ),
        isTrue,
      );
    });

    test('the same call is not shown again after decline or timeout', () {
      expect(
        BackgroundCallKitShow.shouldShow(
          callId: '77',
          terminalCallIds: const {'77'},
          permissionRequestInFlight: false,
        ),
        isFalse,
      );
    });

    test('the permission dialog does not promote to CallKit', () {
      expect(
        BackgroundCallKitShow.shouldShow(
          callId: '80',
          terminalCallIds: const {},
          permissionRequestInFlight: true,
        ),
        isFalse,
      );
    });

    test('a payload without a call id is not shown', () {
      expect(
        BackgroundCallKitShow.shouldShow(
          callId: '  ',
          terminalCallIds: const {},
          permissionRequestInFlight: false,
        ),
        isFalse,
      );
    });
  });
}
