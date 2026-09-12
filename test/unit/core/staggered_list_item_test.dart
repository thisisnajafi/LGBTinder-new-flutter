import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/widgets/staggered_list_item.dart';

void main() {
  test('only the first three rows animate on the first session', () {
    expect(
      StaggeredListItem.shouldAnimate(index: 0, firstSession: true),
      isTrue,
    );
    expect(
      StaggeredListItem.shouldAnimate(index: 2, firstSession: true),
      isTrue,
    );
    expect(
      StaggeredListItem.shouldAnimate(index: 3, firstSession: true),
      isFalse,
    );
    expect(
      StaggeredListItem.shouldAnimate(index: 0, firstSession: false),
      isFalse,
    );
  });
}
