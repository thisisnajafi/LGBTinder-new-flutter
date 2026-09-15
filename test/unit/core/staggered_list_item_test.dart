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

  test('stagger delay index is capped at maxStaggerIndex - 1', () {
    expect(StaggeredListItem.cappedStaggerIndex(0), 0);
    expect(StaggeredListItem.cappedStaggerIndex(2), 2);
    expect(StaggeredListItem.cappedStaggerIndex(99), 2);
    expect(StaggeredListItem.cappedStaggerIndex(-1), 0);
  });
}
