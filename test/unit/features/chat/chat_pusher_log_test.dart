import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/services/app_logger.dart';
import 'package:lgbtindernew/features/chat/utils/chat_pusher_log.dart';
import 'package:lgbtindernew/shared/services/chat_pusher_event_names.dart';

void main() {
  group('ChatPusherLog.preview', () {
    test('truncates to 20 characters', () {
      const body = 'abcdefghijklmnopqrstuvwxyz';
      expect(ChatPusherLog.preview(body), 'abcdefghijklmnopqrst');
      expect(ChatPusherLog.preview(body).length, ChatPusherLog.previewMaxChars);
    });

    test('keeps short bodies and collapses whitespace', () {
      expect(ChatPusherLog.preview('  hi there  '), 'hi there');
      expect(ChatPusherLog.preview(null), '');
    });

    test('counts unicode runes not UTF-16 units', () {
      final body = '💙' * 25;
      expect(ChatPusherLog.preview(body).runes.length, 20);
    });
  });

  group('ChatPusherLog.eventLine', () {
    test('includes event type, conversation id, and preview', () {
      final line = ChatPusherLog.eventLine(
        eventType: ChatPusherEventNames.messageSent,
        conversationId: 42,
        body: 'this is a longer chat message than twenty',
      );
      expect(line, contains('Chat event: MessageSent'));
      expect(line, contains('conversation_id=42'));
      expect(line, contains('preview="this is a longer cha"'));
      expect(
        line.split('preview="').last.replaceAll('"', '').length,
        ChatPusherLog.previewMaxChars,
      );
    });

    test('formats every chat Pusher event type', () {
      const types = [
        ChatPusherEventNames.messageSent,
        ChatPusherEventNames.messageRead,
        ChatPusherEventNames.userTyping,
        ChatPusherEventNames.userStoppedTyping,
        ChatPusherEventNames.messageDeleted,
        ChatPusherEventNames.messageEdited,
        ChatPusherEventNames.messageReacted,
        ChatPusherEventNames.messageDelivered,
        ChatPusherEventNames.messageExpired,
        ChatPusherEventNames.userStatus,
        ChatPusherEventNames.newMatch,
      ];
      for (final type in types) {
        final line = ChatPusherLog.eventLine(
          eventType: type,
          conversationId: 7,
          body: 'ok',
        );
        expect(line, startsWith('Chat event: $type'));
        expect(line, contains('conversation_id=7'));
      }
    });

    test('reads conversation_id from nested message maps', () {
      expect(
        ChatPusherLog.conversationIdOf({
          'message': {'conversation_id': '9', 'content': 'hi'},
        }),
        9,
      );
      expect(ChatPusherLog.bodyOf({'content': 'secret hello'}), 'secret hello');
    });
  });

  test('ChatPusher tag floor is info', () {
    expect(AppLogger.minLevelFor(ChatPusherLog.tag), LogLevel.info);
  });
}
