import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/widgets/animations/lottie_animations.dart';

void main() {
  setUp(LottiePlaybackLimiter.debugReset);
  tearDown(LottiePlaybackLimiter.debugReset);

  test('only one Lottie slot can be held at a time', () {
    expect(LottiePlaybackLimiter.tryAcquire(), isTrue);
    expect(LottiePlaybackLimiter.debugActiveCount, 1);
    expect(LottiePlaybackLimiter.tryAcquire(), isFalse);
    expect(LottiePlaybackLimiter.debugActiveCount, 1);

    LottiePlaybackLimiter.release();
    expect(LottiePlaybackLimiter.debugActiveCount, 0);
    expect(LottiePlaybackLimiter.tryAcquire(), isTrue);
  });
}
