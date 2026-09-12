import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_keyboard_anchor.dart';

void main() {
  test('pins for the whole inset when the user started at the bottom', () {
    final anchor = ChatKeyboardAnchor();
    expect(
      anchor.shouldPinToBottom(insetBottom: 120, nearBottom: true),
      isTrue,
    );
    expect(
      anchor.shouldPinToBottom(insetBottom: 300, nearBottom: false),
      isTrue,
    );
    expect(anchor.isPinned, isTrue);
    expect(
      anchor.shouldPinToBottom(insetBottom: 0, nearBottom: false),
      isTrue,
    );
    expect(anchor.isPinned, isFalse);
  });

  test('does not pin mid-thread when the keyboard opens', () {
    final anchor = ChatKeyboardAnchor();
    expect(
      anchor.shouldPinToBottom(insetBottom: 280, nearBottom: false),
      isFalse,
    );
    expect(
      anchor.shouldPinToBottom(insetBottom: 300, nearBottom: true),
      isFalse,
    );
    expect(
      anchor.shouldPinToBottom(insetBottom: 0, nearBottom: false),
      isFalse,
    );
  });

  test('pinnedExtent is null when already at the reverse origin', () {
    expect(ChatKeyboardAnchor.pinnedExtent(pixels: 0), isNull);
    expect(ChatKeyboardAnchor.pinnedExtent(pixels: 200), 0);
  });
}
