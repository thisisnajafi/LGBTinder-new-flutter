import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call_outgoing_pulse.dart';

void main() {
  group('CallOutgoingPulse', () {
    test('controller duration covers three staggered 1800ms rings', () {
      expect(
        CallOutgoingPulse.controllerDuration,
        const Duration(milliseconds: 2400),
      );
    });

    test('ring 0 runs for the first 1800ms of the loop', () {
      expect(CallOutgoingPulse.ringProgress(0, 0), 0.0);
      expect(CallOutgoingPulse.ringProgress(0, 0.375), closeTo(0.5, 0.001));
      expect(CallOutgoingPulse.ringProgress(0, 0.75), isNull);
    });

    test('ring 1 is delayed by 300ms', () {
      expect(CallOutgoingPulse.ringProgress(1, 0), isNull);
      expect(CallOutgoingPulse.ringProgress(1, 0.125), 0.0);
      expect(CallOutgoingPulse.ringProgress(2, 0.25), 0.0);
    });

    test('scale and opacity follow 1→2 and 20%→0', () {
      expect(CallOutgoingPulse.scaleFor(0), 1.0);
      expect(CallOutgoingPulse.scaleFor(1), 2.0);
      expect(CallOutgoingPulse.opacityFor(0), 0.20);
      expect(CallOutgoingPulse.opacityFor(1), 0.0);
    });
  });
}
