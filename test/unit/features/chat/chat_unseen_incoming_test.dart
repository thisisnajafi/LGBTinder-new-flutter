import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_unseen_incoming.dart';

void main() {
  group('ChatUnseenIncoming', () {
    test('FAB shows only when scrolled up more than 200px from latest', () {
      expect(ChatUnseenIncoming.fabThreshold, 200);
      expect(ChatUnseenIncoming.autoScrollThreshold, 200);

      expect(ChatUnseenIncoming.shouldShowFab(pixels: 200), isFalse);
      expect(ChatUnseenIncoming.shouldShowFab(pixels: 201), isTrue);
    });

    test('isNearBottom uses pixels from the reverse origin', () {
      expect(
        ChatUnseenIncoming.isNearBottom(pixels: 201, threshold: 200),
        isFalse,
      );
      expect(
        ChatUnseenIncoming.isNearBottom(pixels: 150, threshold: 200),
        isTrue,
      );
    });

    test('badge increments only for new peer rows while scrolled up', () {
      expect(
        ChatUnseenIncoming.shouldIncrementBadge(
          insertedNewRow: true,
          fromPeer: true,
          nearBottom: false,
        ),
        isTrue,
      );
      expect(
        ChatUnseenIncoming.shouldIncrementBadge(
          insertedNewRow: true,
          fromPeer: true,
          nearBottom: true,
        ),
        isFalse,
      );
      expect(
        ChatUnseenIncoming.shouldIncrementBadge(
          insertedNewRow: true,
          fromPeer: false,
          nearBottom: false,
        ),
        isFalse,
      );
      expect(
        ChatUnseenIncoming.shouldIncrementBadge(
          insertedNewRow: false,
          fromPeer: true,
          nearBottom: false,
        ),
        isFalse,
      );
    });
  });
}
