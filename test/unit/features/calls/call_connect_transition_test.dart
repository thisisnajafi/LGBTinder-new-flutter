import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/data/models/call_connect_transition.dart';

void main() {
  group('CallConnectTransition', () {
    test('reduce motion duration is zero', () {
      expect(
        CallConnectTransition.duration(reduceMotion: true),
        Duration.zero,
      );
      expect(
        CallConnectTransition.duration(reduceMotion: false),
        AppAnimations.callConnect,
      );
      expect(AppAnimations.callConnect, const Duration(milliseconds: 400));
    });

    test('t=0 is ringing chrome', () {
      expect(CallConnectTransition.pulseOpacity(0), 1);
      expect(CallConnectTransition.pulseScale(0), 1);
      expect(CallConnectTransition.stageOpacity(0), 0);
      expect(
        CallConnectTransition.stageScale(0),
        AppAnimations.callConnectStageBeginScale,
      );
      expect(CallConnectTransition.timerOpacity(0), 0);
      expect(
        CallConnectTransition.timerSlideY(0),
        AppAnimations.callConnectTimerSlide,
      );
    });

    test('t=1 is connected chrome', () {
      expect(CallConnectTransition.pulseOpacity(1), 0);
      expect(
        CallConnectTransition.pulseScale(1),
        AppAnimations.callConnectPulseEndScale,
      );
      expect(CallConnectTransition.stageOpacity(1), 1);
      expect(CallConnectTransition.stageScale(1), 1);
      expect(CallConnectTransition.timerOpacity(1), 1);
      expect(CallConnectTransition.timerSlideY(1), 0);
    });
  });
}
