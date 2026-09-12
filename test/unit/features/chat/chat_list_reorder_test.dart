import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/chat/utils/chat_list_reorder.dart';

void main() {
  test('slide-to-top uses 350ms easeOutCubic', () {
    expect(AppAnimations.chatListReorder, const Duration(milliseconds: 350));
    expect(AppAnimations.curveDefault, Curves.easeOutCubic);
  });

  test('hydrate and same slot do not animate', () {
    expect(
      ChatListReorder.shouldAnimate(previousIndex: 2, index: 2),
      isFalse,
    );
  });

  test('existing row moving to top animates from its old slot', () {
    expect(
      ChatListReorder.shouldAnimate(previousIndex: 3, index: 0),
      isTrue,
    );
    expect(
      ChatListReorder.slidePixels(previousIndex: 3, index: 0),
      3 * ChatListReorder.rowStride,
    );
  });

  test('new top row slides in from above', () {
    expect(
      ChatListReorder.shouldAnimate(previousIndex: -1, index: 0),
      isTrue,
    );
    expect(
      ChatListReorder.slidePixels(previousIndex: -1, index: 0),
      -ChatListReorder.rowStride,
    );
  });

  test('new row not at top does not animate', () {
    expect(
      ChatListReorder.shouldAnimate(previousIndex: -1, index: 2),
      isFalse,
    );
  });

  test('neighbors shift down when another row is promoted', () {
    expect(
      ChatListReorder.shouldAnimate(previousIndex: 0, index: 1),
      isTrue,
    );
    expect(
      ChatListReorder.slidePixels(previousIndex: 0, index: 1),
      -ChatListReorder.rowStride,
    );
  });
}
