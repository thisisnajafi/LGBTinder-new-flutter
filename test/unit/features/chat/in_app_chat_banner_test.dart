import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/data/models/message.dart';
import 'package:lgbtindernew/features/chat/utils/in_app_chat_banner.dart';

void main() {
  group('InAppChatBannerPolicy.shouldPresent', () {
    test('shows for another chat while the app is in the foreground', () {
      expect(
        InAppChatBannerPolicy.shouldPresent(
          isChatPayload: true,
          suppressedOpenOrMuted: false,
          isOwnMessage: false,
          appForeground: true,
        ),
        isTrue,
      );
    });

    test('hides for the open or muted chat', () {
      expect(
        InAppChatBannerPolicy.shouldPresent(
          isChatPayload: true,
          suppressedOpenOrMuted: true,
          isOwnMessage: false,
          appForeground: true,
        ),
        isFalse,
      );
    });

    test('hides own messages, non-chat, and background', () {
      expect(
        InAppChatBannerPolicy.shouldPresent(
          isChatPayload: true,
          suppressedOpenOrMuted: false,
          isOwnMessage: true,
          appForeground: true,
        ),
        isFalse,
      );
      expect(
        InAppChatBannerPolicy.shouldPresent(
          isChatPayload: false,
          suppressedOpenOrMuted: false,
          isOwnMessage: false,
          appForeground: true,
        ),
        isFalse,
      );
      expect(
        InAppChatBannerPolicy.shouldPresent(
          isChatPayload: true,
          suppressedOpenOrMuted: false,
          isOwnMessage: false,
          appForeground: false,
        ),
        isFalse,
      );
    });
  });

  group('InAppChatBannerPolicy.push', () {
    const first = InAppChatBannerItem(
      id: '1',
      peerUserId: 10,
      title: 'A',
      body: 'Hi',
    );
    const second = InAppChatBannerItem(
      id: '2',
      peerUserId: 20,
      title: 'B',
      body: 'Yo',
    );
    const third = InAppChatBannerItem(
      id: '3',
      peerUserId: 30,
      title: 'C',
      body: 'Hey',
    );

    test('caps at two and keeps the newest', () {
      final stacked = InAppChatBannerPolicy.push(
        InAppChatBannerPolicy.push(const [first], second),
        third,
      );
      expect(stacked.map((e) => e.id), ['2', '3']);
    });

    test('replaces the same peer in place and moves it to newest', () {
      const updated = InAppChatBannerItem(
        id: '1b',
        peerUserId: 10,
        title: 'A',
        body: 'Later',
      );
      final stacked = InAppChatBannerPolicy.push(const [first, second], updated);
      expect(stacked.map((e) => e.id), ['2', '1b']);
      expect(stacked.last.body, 'Later');
    });
  });

  group('InAppChatBannerPolicy parsers', () {
    test('fromFcm uses data-only fields', () {
      final item = InAppChatBannerPolicy.fromFcm({
        'type': 'message',
        'sender_id': '42',
        'message_id': '99',
        'user_name': 'Alex',
        'message_preview': 'Hello there',
        'sender_avatar': 'https://cdn.example/a.jpg',
      });
      expect(item?.id, '99');
      expect(item?.peerUserId, 42);
      expect(item?.title, 'Alex');
      expect(item?.body, 'Hello there');
      expect(item?.avatarUrl, 'https://cdn.example/a.jpg');
    });

    test('fromFcm redacts hidden sender and body', () {
      final item = InAppChatBannerPolicy.fromFcm({
        'type': 'chat',
        'user_id': '7',
        'hide_sender': '1',
        'content_redacted': '1',
        'user_name': 'Alex',
        'message_preview': 'secret',
      });
      expect(item?.title, 'Someone');
      expect(item?.body, 'Sent you a message');
      expect(item?.avatarUrl, isNull);
    });

    test('fromMessage uses preview helpers', () {
      final item = InAppChatBannerPolicy.fromMessage(
        Message(
          id: 15,
          senderId: 8,
          receiverId: 1,
          message: 'ignored for image',
          messageType: 'image',
          createdAt: DateTime.utc(2026, 1, 1),
          metadata: {'sender_name': 'Sam'},
        ),
      );
      expect(item.id, '15');
      expect(item.peerUserId, 8);
      expect(item.title, 'Sam');
      expect(item.body, 'Photo');
    });
  });
}
