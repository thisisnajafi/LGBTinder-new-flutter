import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'self_destruct_send.dart';

/// Countdown ring color drain and remaining-time math (CHAT-SD-002 / CHAT-SD-003).
class SelfDestructCountdown {
  SelfDestructCountdown._();

  static const Duration tickInterval = Duration(milliseconds: 100);

  static const Duration fadeToBlack = Duration(milliseconds: 300);

  static const Duration disappearedHold = Duration(seconds: 1);

  static const String disappearedCopy = 'Photo has disappeared';

  /// [progress] 1.0 = full time remaining, 0.0 = empty.
  static Color drainColor(double progress) {
    final t = progress.clamp(0.0, 1.0);
    if (t >= 0.5) {
      return Color.lerp(
        AppColors.feedbackWarning,
        AppColors.primaryLight,
        (t - 0.5) * 2,
      )!;
    }
    return Color.lerp(
      AppColors.feedbackError,
      AppColors.feedbackWarning,
      t * 2,
    )!;
  }

  /// Remaining window from the server clock, not the tap instant.
  static Duration remainingFromPayload({
    String? expiresAtIso,
    int? remainingSeconds,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (expiresAtIso != null && expiresAtIso.isNotEmpty) {
      final expiresAt = DateTime.tryParse(expiresAtIso);
      if (expiresAt != null) {
        final delta = expiresAt.toLocal().difference(clock.toLocal());
        if (delta.isNegative) return Duration.zero;
        return delta;
      }
    }
    if (remainingSeconds != null && remainingSeconds > 0) {
      return Duration(seconds: remainingSeconds);
    }
    return const Duration(seconds: SelfDestructSend.defaultViewSeconds);
  }

  static double ringProgress({
    required Duration remaining,
    required Duration total,
  }) {
    final totalMs = total.inMilliseconds;
    if (totalMs <= 0) return 0;
    return (remaining.inMilliseconds / totalMs).clamp(0.0, 1.0);
  }

  static int displaySeconds(Duration remaining) {
    final ms = remaining.inMilliseconds;
    if (ms <= 0) return 0;
    final seconds = remaining.inSeconds;
    return seconds == 0 ? 1 : seconds;
  }
}
