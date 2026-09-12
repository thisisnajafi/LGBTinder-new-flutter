import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/data/models/call_speaking_pulse.dart';
import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

void main() {
  group('CallSpeakingPulse', () {
    test('duration is 400ms', () {
      expect(CallSpeakingPulse.duration, const Duration(milliseconds: 400));
      expect(AppAnimations.callSpeakingPulse, CallSpeakingPulse.duration);
    });

    test('scale and opacity follow 1→1.12 and 0.8→0', () {
      expect(CallSpeakingPulse.scaleFor(0), 1.0);
      expect(CallSpeakingPulse.scaleFor(1), 1.12);
      expect(CallSpeakingPulse.opacityFor(0), 0.8);
      expect(CallSpeakingPulse.opacityFor(1), 0.0);
    });

    test('volume threshold matches AgoraSpeaking', () {
      expect(
        CallSpeakingPulse.volumeThreshold,
        AgoraSpeaking.volumeThreshold,
      );
    });
  });

  group('AgoraSpeaking', () {
    test('silence at 0 is not speaking', () {
      expect(AgoraSpeaking.isActive(volume: 0), isFalse);
      expect(AgoraSpeaking.isActive(volume: 15), isFalse);
    });

    test('volume above threshold or VAD is speaking', () {
      expect(AgoraSpeaking.isActive(volume: 16), isTrue);
      expect(AgoraSpeaking.isActive(volume: 0, vad: 1), isTrue);
    });
  });
}
