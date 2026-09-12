import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/services/app_logger.dart';

void main() {
  group('AppLogger.minLevelFor', () {
    test('Agora tag shows info and above; verbose stays below the floor', () {
      expect(AppLogger.minLevelFor('Agora'), LogLevel.info);
      expect(LogLevel.verbose.index < AppLogger.minLevelFor('Agora').index, isTrue);
      expect(LogLevel.warning.index >= AppLogger.minLevelFor('Agora').index, isTrue);
      expect(LogLevel.error.index >= AppLogger.minLevelFor('Agora').index, isTrue);
    });

    test('untagged and other tags keep the quiet error floor', () {
      expect(AppLogger.minLevelFor(null), LogLevel.error);
      expect(AppLogger.minLevelFor('CallQuality'), LogLevel.error);
      expect(AppLogger.minLevelFor('CallSignaling'), LogLevel.info);
      expect(AppLogger.minLevelFor('ChatPusher'), LogLevel.info);
      expect(AppLogger.minLevelFor('ChatOutbox'), LogLevel.info);
    });

    test('Chat, Pusher, and Notifications tags show warning and above', () {
      expect(AppLogger.minLevelFor('Chat'), LogLevel.warning);
      expect(AppLogger.minLevelFor('ChatPage'), LogLevel.warning);
      expect(AppLogger.minLevelFor('chat_page'), LogLevel.warning);
      expect(AppLogger.minLevelFor('ChatListPreview'), LogLevel.warning);
      expect(AppLogger.minLevelFor('Pusher'), LogLevel.warning);
      expect(AppLogger.minLevelFor('Notifications'), LogLevel.warning);
      expect(
        LogLevel.debug.index < AppLogger.minLevelFor('Chat').index,
        isTrue,
      );
    });
  });
}
