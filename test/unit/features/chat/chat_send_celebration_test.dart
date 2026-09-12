import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_send_celebration.dart';

void main() {
  group('ChatSendCelebration.shouldCelebrate', () {
    test('single emoji celebrates', () {
      expect(ChatSendCelebration.shouldCelebrateText('😂'), isTrue);
      expect(ChatSendCelebration.shouldCelebrateText(' ❤️ '), isTrue);
      expect(ChatSendCelebration.shouldCelebrateText('👍🏽'), isTrue);
    });

    test('plain text and multi-emoji do not celebrate', () {
      expect(ChatSendCelebration.shouldCelebrateText('hello'), isFalse);
      expect(ChatSendCelebration.shouldCelebrateText('😂😂'), isFalse);
      expect(ChatSendCelebration.shouldCelebrateText('ok 😂'), isFalse);
      expect(ChatSendCelebration.shouldCelebrateText('A'), isFalse);
      expect(ChatSendCelebration.shouldCelebrateText(''), isFalse);
    });

    test('sticker type always celebrates', () {
      expect(
        ChatSendCelebration.shouldCelebrate(
          text: '',
          messageType: 'sticker',
        ),
        isTrue,
      );
      expect(
        ChatSendCelebration.shouldCelebrate(
          text: 'hello',
          messageType: 'text',
        ),
        isFalse,
      );
    });
  });
}
