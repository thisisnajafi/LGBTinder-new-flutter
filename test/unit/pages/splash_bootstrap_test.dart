import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/pages/splash_page.dart';

void main() {
  test('intro and token checks run in parallel', () {
    fakeAsync((async) {
      ({bool hasSeenIntro, bool hasToken})? gate;
      splashLoadGate(
        hasSeenIntro: Future<bool>.delayed(
          const Duration(milliseconds: 80),
          () => true,
        ),
        hasToken: Future<bool>.delayed(
          const Duration(milliseconds: 80),
          () => false,
        ),
      ).then((value) => gate = value);

      async.elapse(const Duration(milliseconds: 80));
      expect(gate, isNotNull);
      expect(gate!.hasSeenIntro, isTrue);
      expect(gate!.hasToken, isFalse);
    });
  });

  test('cached auth skips the branding delay', () {
    expect(splashBrandingDelay(hasCachedAuth: true), Duration.zero);
    expect(
      splashBrandingDelay(hasCachedAuth: false),
      const Duration(milliseconds: 400),
    );
  });
}
