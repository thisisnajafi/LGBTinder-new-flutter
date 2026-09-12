import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/services/chat_pusher_event_names.dart';

void main() {
  test('Flutter handles every backend config event name', () {
    for (final name in ChatPusherEventNames.fromBackendConfig) {
      expect(
        ChatPusherEventNames.isHandled(name),
        isTrue,
        reason: 'config events value "$name" must be handled',
      );
    }
  });

  test('Flutter handles every backend legacy event alias', () {
    for (final name in ChatPusherEventNames.legacyFromBackendConfig) {
      expect(
        ChatPusherEventNames.isHandled(name),
        isTrue,
        reason: 'legacy alias "$name" must be handled',
      );
    }
  });

  test('canonicalize maps aliases to live handlers', () {
    expect(
      ChatPusherEventNames.canonicalize('message.sent'),
      ChatPusherEventNames.messageSent,
    );
    expect(
      ChatPusherEventNames.canonicalize('presence.updated'),
      ChatPusherEventNames.userStatus,
    );
    expect(
      ChatPusherEventNames.canonicalize('call.initiated'),
      ChatPusherEventNames.callIncoming,
    );
    expect(
      ChatPusherEventNames.canonicalize('NewMatch'),
      ChatPusherEventNames.newMatch,
    );
    expect(
      ChatPusherEventNames.canonicalize('MessageSent'),
      ChatPusherEventNames.messageSent,
    );
    expect(
      ChatPusherEventNames.canonicalize('message.reacted'),
      ChatPusherEventNames.messageReacted,
    );
    expect(ChatPusherEventNames.isHandled('MessageReacted'), isTrue);
    expect(ChatPusherEventNames.isHandled('ScreenshotDetected'), isTrue);
    expect(
      ChatPusherEventNames.canonicalize('screenshot.detected'),
      ChatPusherEventNames.screenshotDetected,
    );
  });

  test('deferred feature names stay unhandled until those features ship', () {
    expect(ChatPusherEventNames.isHandled('TypingStarted'), isFalse);
  });
}
