import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/utils/call_local_busy.dart';

void main() {
  group('CallLocalBusy.shouldMarkBusy', () {
    test('idle device is not busy', () {
      expect(
        CallLocalBusy.shouldMarkBusy(incomingCallId: '10'),
        isFalse,
      );
    });

    test('second banner while another incoming is showing is busy', () {
      expect(
        CallLocalBusy.shouldMarkBusy(
          incomingCallId: '10',
          showingBannerCallId: '9',
        ),
        isTrue,
      );
    });

    test('active call, minimized session, or Agora marks busy', () {
      expect(
        CallLocalBusy.shouldMarkBusy(
          incomingCallId: '10',
          providerActiveCallId: 4,
        ),
        isTrue,
      );
      expect(
        CallLocalBusy.shouldMarkBusy(
          incomingCallId: '10',
          sessionCallId: 4,
        ),
        isTrue,
      );
      expect(
        CallLocalBusy.shouldMarkBusy(
          incomingCallId: '10',
          agoraInCall: true,
        ),
        isTrue,
      );
    });

    test('same-call replay is not busy', () {
      expect(
        CallLocalBusy.shouldMarkBusy(
          incomingCallId: '10',
          showingBannerCallId: '10',
          agoraInCall: true,
        ),
        isFalse,
      );
      expect(
        CallLocalBusy.shouldMarkBusy(
          incomingCallId: '10',
          acceptedCallId: '10',
          providerActiveCallId: 10,
        ),
        isFalse,
      );
      expect(
        CallLocalBusy.shouldMarkBusy(
          incomingCallId: '10',
          sessionCallId: 10,
        ),
        isFalse,
      );
    });
  });
}
