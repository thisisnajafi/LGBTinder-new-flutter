import 'dart:math' as math;

import '../../../core/constants/animation_constants.dart';

/// Layout math for the voice waveform painter (CHAT-ANIM-011).
class VoiceWaveformLayout {
  VoiceWaveformLayout._();

  static const double gap = 2.4;
  static const double minBarWidth = 2.2;
  static const double mutedAlphaActive = 0.42;
  static const double mutedAlphaIdle = 0.34;

  static int get barCount => AppAnimations.chatVoiceWaveformBars;

  static double barWidth(double maxWidth, int barCount) {
    if (barCount <= 0) return minBarWidth;
    final gapTotal = gap * (barCount - 1);
    return math.max(minBarWidth, (maxWidth - gapTotal) / barCount);
  }

  /// Deterministic idle heights so a paused waveform still looks natural.
  static double idleHeightFactor(int index, int barCount) {
    if (barCount <= 0) return 0.5;
    final phase = (index / barCount) * math.pi * 2.4;
    final wave = (math.sin(phase) + math.sin(phase * 1.7 + 0.6)) / 2;
    return (0.28 + (wave + 1) * 0.32).clamp(0.22, 0.92);
  }

  static double heightFactor({
    required int index,
    required int barCount,
    required double t,
    required bool active,
    required bool animate,
  }) {
    if (!active || !animate) {
      return idleHeightFactor(index, barCount);
    }
    final phase = (index / barCount) * math.pi * 2;
    return 0.32 +
        0.68 * ((math.sin(t * math.pi * 2 + phase) + 1) / 2);
  }

  /// 1 = fully played (primary), 0 = remaining (muted). Boundary bar is lerped.
  static double playedFraction({
    required int index,
    required int barCount,
    required double progress,
  }) {
    if (barCount <= 0) return 0;
    return (progress.clamp(0.0, 1.0) * barCount - index).clamp(0.0, 1.0);
  }
}

/// Drops audio-position setState bursts to [AppAnimations.chatVoiceWaveformTick].
class ChatVoicePositionGate {
  ChatVoicePositionGate({
    this.minInterval = AppAnimations.chatVoiceWaveformTick,
  });

  final Duration minInterval;
  DateTime? _last;

  bool allow(DateTime now) {
    if (_last == null || now.difference(_last!) >= minInterval) {
      _last = now;
      return true;
    }
    return false;
  }

  void reset() => _last = null;
}
