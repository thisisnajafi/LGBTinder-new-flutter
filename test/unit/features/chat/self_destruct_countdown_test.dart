import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/theme/app_colors.dart';
import 'package:lgbtindernew/features/chat/utils/self_destruct_countdown.dart';
import 'package:lgbtindernew/features/chat/utils/self_destruct_send.dart';

void main() {
  test('countdown ring drains primary to amber to error', () {
    expect(SelfDestructCountdown.drainColor(1.0), AppColors.primaryLight);
    expect(SelfDestructCountdown.drainColor(0.5), AppColors.feedbackWarning);
    expect(SelfDestructCountdown.drainColor(0.0), AppColors.feedbackError);
  });

  test('remaining prefers expires_at over remaining_seconds', () {
    final now = DateTime.utc(2026, 9, 11, 12, 0, 0);
    final expires = now.add(const Duration(seconds: 8));
    expect(
      SelfDestructCountdown.remainingFromPayload(
        expiresAtIso: expires.toIso8601String(),
        remainingSeconds: 30,
        now: now,
      ),
      const Duration(seconds: 8),
    );
  });

  test('remaining falls back to remaining_seconds then default', () {
    expect(
      SelfDestructCountdown.remainingFromPayload(remainingSeconds: 5),
      const Duration(seconds: 5),
    );
    expect(
      SelfDestructCountdown.remainingFromPayload(),
      const Duration(seconds: SelfDestructSend.defaultViewSeconds),
    );
  });

  test('past expires_at yields zero remaining', () {
    final now = DateTime.utc(2026, 9, 11, 12, 0, 0);
    expect(
      SelfDestructCountdown.remainingFromPayload(
        expiresAtIso: now
            .subtract(const Duration(seconds: 2))
            .toIso8601String(),
        now: now,
      ),
      Duration.zero,
    );
  });

  test('display seconds keeps last partial second as 1', () {
    expect(
      SelfDestructCountdown.displaySeconds(const Duration(milliseconds: 1)),
      1,
    );
    expect(SelfDestructCountdown.displaySeconds(Duration.zero), 0);
    expect(
      SelfDestructCountdown.displaySeconds(const Duration(seconds: 10)),
      10,
    );
    expect(
      SelfDestructCountdown.displaySeconds(
        const Duration(milliseconds: 10001),
      ),
      10,
    );
  });

  test('ring progress is remaining over total', () {
    expect(
      SelfDestructCountdown.ringProgress(
        remaining: const Duration(seconds: 5),
        total: const Duration(seconds: 10),
      ),
      0.5,
    );
  });
}
