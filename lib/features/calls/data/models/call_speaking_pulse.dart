import '../../../../core/constants/animation_constants.dart';

/// Timing for CALL-UI-005 active-speaker rings.
class CallSpeakingPulse {
  CallSpeakingPulse._();

  static Duration get duration => AppAnimations.callSpeakingPulse;

  static const double startScale = 1.0;
  static double get endScale => AppAnimations.callSpeakingEndScale;

  static double get startOpacity => AppAnimations.callSpeakingStartOpacity;
  static const double endOpacity = 0.0;

  /// Matches [AgoraSpeaking.volumeThreshold] in `agora_rtc_types.dart`.
  static const int volumeThreshold = 15;

  static double scaleFor(double progress) =>
      startScale + (endScale - startScale) * progress;

  static double opacityFor(double progress) =>
      startOpacity + (endOpacity - startOpacity) * progress;
}
