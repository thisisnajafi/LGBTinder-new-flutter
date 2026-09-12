import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/chat/utils/chat_fcm_suppress.dart';

void main() {
  group('ChatFcmSuppress', () {
    test('treats chat and new_message as chat payloads', () {
      expect(ChatFcmSuppress.isChatPayload({'type': 'message'}), isTrue);
      expect(ChatFcmSuppress.isChatPayload({'type': 'chat'}), isTrue);
      expect(ChatFcmSuppress.isChatPayload({'type': 'new_message'}), isTrue);
      expect(ChatFcmSuppress.isChatPayload({'type': 'like'}), isFalse);
    });

    test('suppresses FCM for the open peer', () {
      expect(
        ChatFcmSuppress.shouldSuppress(
          {'type': 'message', 'sender_id': '42'},
          isActivePeer: (id) => id == 42,
        ),
        isTrue,
      );
    });

    test('suppresses FCM when conversation_id matches the open thread', () {
      expect(
        ChatFcmSuppress.shouldSuppress(
          {
            'type': 'chat',
            'conversation_id': '99',
            'sender_id': '7',
          },
          isActiveConversation: (id) => id == 99,
        ),
        isTrue,
      );
    });

    test('does not suppress other peers', () {
      expect(
        ChatFcmSuppress.shouldSuppress(
          {
            'type': 'message',
            'sender_id': '7',
            'conversation_id': '12',
          },
          isActivePeer: (id) => id == 42,
          isActiveConversation: (id) => id == 99,
        ),
        isFalse,
      );
    });

    test('suppresses muted peers even when the chat is not open', () {
      expect(
        ChatFcmSuppress.shouldSuppress(
          {'type': 'message', 'sender_id': '7'},
          isMutedPeer: (id) => id == 7,
        ),
        isTrue,
      );
    });

    test('open-chat match is independent of mute', () {
      expect(
        ChatFcmSuppress.matchesOpenChat(
          {'type': 'message', 'user_id': 42, 'conversation_id': 99},
          activePeerUserId: 42,
          activeConversationId: 99,
        ),
        isTrue,
      );
      expect(
        ChatFcmSuppress.matchesOpenChat(
          {'type': 'message', 'sender_id': 7},
          activePeerUserId: 42,
        ),
        isFalse,
      );
    });
  });
}
