import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/pages/home_page.dart';

void main() {
  test('idle dispose drops notifications and settings but keeps current tab', () {
    expect(
      homeTabsAfterIdleDispose(
        mounted: {0, 1, 2, 3, 4},
        currentIndex: 0,
      ),
      {0, 1, 3},
    );
    expect(
      homeTabsAfterIdleDispose(
        mounted: {0, 2, 4},
        currentIndex: 2,
      ),
      {0, 2},
    );
    expect(homeIdleDisposableTabs, {2, 4});
    expect(homeIdleTabDisposeAfter, const Duration(minutes: 5));
  });
}
