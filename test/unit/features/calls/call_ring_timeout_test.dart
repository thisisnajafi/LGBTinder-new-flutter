import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/utils/call_ring_timeout.dart';

void main() {
  group('CallRingTimeout', () {
    test('is 45 seconds for job, cron, banner, and CallKit', () {
      expect(CallRingTimeout.seconds, 45);
      expect(CallRingTimeout.duration, const Duration(seconds: 45));
      expect(CallRingTimeout.milliseconds, 45000);
      expect(CallRingTimeout.callerTimeoutReason, 'caller-timeout');
      expect(CallRingTimeout.acceptingGraceSeconds, 60);
      expect(CallRingTimeout.acceptingGrace, const Duration(seconds: 60));
    });
  });
}
