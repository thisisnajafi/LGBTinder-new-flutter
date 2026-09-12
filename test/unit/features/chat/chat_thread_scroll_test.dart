import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_thread_scroll.dart';

void main() {
  test('chronologicalIndex maps reverse builder indexes', () {
    expect(ChatThreadScroll.chronologicalIndex(10, 0), 9);
    expect(ChatThreadScroll.chronologicalIndex(10, 9), 0);
    expect(ChatThreadScroll.chronologicalIndex(0, 0), 0);
  });

  test('near latest is pixels from 0; near oldest is max extent', () {
    expect(ChatThreadScroll.isNearLatest(pixels: 0), isTrue);
    expect(ChatThreadScroll.isNearLatest(pixels: 200), isTrue);
    expect(ChatThreadScroll.isNearLatest(pixels: 201), isFalse);

    expect(
      ChatThreadScroll.isNearOldest(pixels: 880, maxScrollExtent: 1000),
      isTrue,
    );
    expect(
      ChatThreadScroll.isNearOldest(pixels: 800, maxScrollExtent: 1000),
      isFalse,
    );
  });

  test('pinnedLatestPixels jumps to 0 unless already there', () {
    expect(ChatThreadScroll.pinnedLatestPixels(pixels: 0), isNull);
    expect(ChatThreadScroll.pinnedLatestPixels(pixels: 40), 0);
  });
}
