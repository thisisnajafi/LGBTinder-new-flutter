import '../../../../core/constants/animation_constants.dart';

/// Interpolation for CALL-UI-002 (ringing → connected).
///
/// [t] is 0 while ringing and 1 when the connected layout is showing.
class CallConnectTransition {
  CallConnectTransition._();

  static Duration duration({required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : AppAnimations.callConnect;

  static double pulseOpacity(double t) => (1.0 - t).clamp(0.0, 1.0);

  static double pulseScale(double t) =>
      1.0 -
      (1.0 - AppAnimations.callConnectPulseEndScale) * t.clamp(0.0, 1.0);

  static double stageOpacity(double t) => t.clamp(0.0, 1.0);

  static double stageScale(double t) =>
      AppAnimations.callConnectStageBeginScale +
      (1.0 - AppAnimations.callConnectStageBeginScale) * t.clamp(0.0, 1.0);

  static double timerOpacity(double t) => t.clamp(0.0, 1.0);

  static double timerSlideY(double t) =>
      AppAnimations.callConnectTimerSlide * (1.0 - t.clamp(0.0, 1.0));
}
