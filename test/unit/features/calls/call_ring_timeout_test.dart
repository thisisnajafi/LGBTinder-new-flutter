import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/utils/call_ring_timeout.dart';

void main() {
  group('CallRingTimeout', () {
    test('is 45 seconds for job, cron, banner, and CallKit', () {
      expect(CallRingTimeout.seconds, 45);
      expect(CallRingTimeout.duration, const Duration(seconds: 45));
      expect(CallRingTimeout.milliseconds, 45000);
    });
  });
}
