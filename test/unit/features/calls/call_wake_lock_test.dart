import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call_wake_lock.dart';

void main() {
  group('CallWakeLock', () {
    test('second enable does not call the plugin again', () async {
      var enables = 0;
      final lock = CallWakeLock(
        enableFn: () async {
          enables++;
        },
        disableFn: () async {},
      );

      await lock.enable();
      await lock.enable();

      expect(enables, 1);
      expect(lock.isHeld, isTrue);
    });

    test('disable is skipped until enabled, unless force', () async {
      var disables = 0;
      final lock = CallWakeLock(
        enableFn: () async {},
        disableFn: () async {
          disables++;
        },
      );

      await lock.disable();
      expect(disables, 0);

      await lock.disable(force: true);
      expect(disables, 1);
      expect(lock.isHeld, isFalse);
    });

    test('enable then disable releases the lock', () async {
      var disables = 0;
      final lock = CallWakeLock(
        enableFn: () async {},
        disableFn: () async {
          disables++;
        },
      );

      await lock.enable();
      await lock.disable();

      expect(disables, 1);
      expect(lock.isHeld, isFalse);
    });
  });
}
