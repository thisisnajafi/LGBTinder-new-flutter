import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call_hud_policy.dart';

void main() {
  group('CallHudPolicy.autoHide', () {
    test('video hides only after the call is connected', () {
      expect(
        CallHudPolicy.autoHide(isVideo: true, connected: false),
        isFalse,
      );
      expect(
        CallHudPolicy.autoHide(isVideo: true, connected: true),
        isTrue,
      );
    });

    test('voice never auto-hides', () {
      expect(
        CallHudPolicy.autoHide(isVideo: false, connected: false),
        isFalse,
      );
      expect(
        CallHudPolicy.autoHide(isVideo: false, connected: true),
        isFalse,
      );
    });
  });
}
