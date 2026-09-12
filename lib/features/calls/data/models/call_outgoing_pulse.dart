import '../../../../core/constants/animation_constants.dart';

/// Timing for CALL-UI-001 concentric outgoing-call rings.
class CallOutgoingPulse {
  CallOutgoingPulse._();

  static const int ringCount = 3;
  static const double peakOpacity = 0.20;
  static const double startScale = 1.0;
  static const double endScale = 2.0;

  static Duration get controllerDuration =>
      AppAnimations.callOutgoingPulse +
      AppAnimations.callOutgoingPulseStagger * (ringCount - 1);

  /// 0–1 progress for ring [index], or null if that ring is idle this frame.
  /// Maps the same ranges as three [Interval]s on a 2400ms controller.
  static double? ringProgress(int index, double t) {
    if (index < 0 || index >= ringCount) return null;
    final totalMs = controllerDuration.inMilliseconds;
    if (totalMs <= 0) return null;
    final start = index *
        AppAnimations.callOutgoingPulseStagger.inMilliseconds /
        totalMs;
    final end = start +
        AppAnimations.callOutgoingPulse.inMilliseconds / totalMs;
    if (t < start || t >= end) return null;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double scaleFor(double progress) =>
      startScale + (endScale - startScale) * progress;

  static double opacityFor(double progress) =>
      peakOpacity * (1.0 - progress);
}
