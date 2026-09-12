import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/utils/screenshot_protection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enable and disable do not throw without a native plugin', () async {
    await ScreenshotProtection.enable();
    await ScreenshotProtection.disable();
  });
}
