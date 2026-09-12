import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/utils/call_quality_toast_gate.dart';
import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

void main() {
  final debounce = const Duration(seconds: 5);
  final t0 = DateTime.utc(2026, 9, 11, 12);

  test('toasts only Agora quality 4–5 (bad), not poor', () {
    expect(AgoraNetworkQuality.shouldToast(AgoraNetworkQuality.bad), isTrue);
    expect(AgoraNetworkQuality.shouldToast(AgoraNetworkQuality.poor), isFalse);
    expect(AgoraNetworkQuality.shouldToast(AgoraNetworkQuality.good), isFalse);
  });

  test('shows once per bad episode and ignores ticks in-band', () {
    final gate = CallQualityToastGate(debounce: debounce);
    expect(
      gate.take(quality: AgoraNetworkQuality.bad, now: t0),
      isTrue,
    );
    expect(
      gate.take(quality: AgoraNetworkQuality.bad, now: t0.add(const Duration(seconds: 1))),
      isFalse,
    );
  });

  test('debounces a second toast for 5s after leaving the band', () {
    final gate = CallQualityToastGate(debounce: debounce);
    expect(gate.take(quality: AgoraNetworkQuality.bad, now: t0), isTrue);
    expect(
      gate.take(quality: AgoraNetworkQuality.good, now: t0.add(const Duration(seconds: 1))),
      isFalse,
    );
    expect(
      gate.take(
        quality: AgoraNetworkQuality.bad,
        now: t0.add(const Duration(seconds: 4)),
      ),
      isFalse,
    );
    expect(
      gate.take(
        quality: AgoraNetworkQuality.bad,
        now: t0.add(const Duration(seconds: 5)),
      ),
      isTrue,
    );
  });

  test('hold is 3s and debounce is 5s', () {
    expect(AppAnimations.callQualityToastHold, const Duration(seconds: 3));
    expect(AppAnimations.callQualityToastDebounce, const Duration(seconds: 5));
  });
}
