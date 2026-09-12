import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/core/utils/app_device_name.dart';

void main() {
  tearDown(AppDeviceName.resetForTest);

  test('resolve memoizes the in-flight future', () {
    AppDeviceName.resetForTest();
    final first = AppDeviceName.resolve();
    final second = AppDeviceName.resolve();
    expect(identical(first, second), isTrue);
  });

  test('resolve returns a stable device label', () async {
    final name = await AppDeviceName.resolve();
    expect(name, isNotEmpty);
    expect(await AppDeviceName.resolve(), name);
  });
}
