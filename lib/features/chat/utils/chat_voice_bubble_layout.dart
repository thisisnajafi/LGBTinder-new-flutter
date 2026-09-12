import 'dart:math' as math;

/// Voice bubble width and playback-speed helpers (CHAT-BUBBLE-006).
class ChatVoiceBubbleLayout {
  ChatVoiceBubbleLayout._();

  static const double minWidth = 120;
  static const double maxWidthCap = 280;
  static const int fullDurationSeconds = 60;
  static const List<double> speeds = [1.0, 1.5, 2.0];

  /// Grows from [minWidth] at ≤1s up to [maxWidth] at [fullDurationSeconds].
  static double width({
    required int? durationSeconds,
    required double maxWidth,
  }) {
    final cap = math.max(minWidth, math.min(maxWidth, maxWidthCap));
    final seconds = durationSeconds ?? 0;
    if (seconds <= 1) return minWidth;
    final span = math.max(1, fullDurationSeconds - 1);
    final t = ((seconds - 1) / span).clamp(0.0, 1.0);
    return minWidth + (cap - minWidth) * t;
  }

  static double nextSpeed(double current) {
    final index = speeds.indexWhere((step) => (step - current).abs() < 0.01);
    final from = index < 0 ? 0 : index;
    return speeds[(from + 1) % speeds.length];
  }

  static String speedLabel(double speed) {
    if (speed == speed.roundToDouble()) return '${speed.toInt()}x';
    return '${speed}x';
  }
}
