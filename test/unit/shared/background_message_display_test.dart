import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/services/background_message_display.dart';

void main() {
  group('BackgroundMessageDisplay', () {
    test('chat tray uses the sender name and message preview', () {
      final copy = BackgroundMessageDisplay.chatTrayCopy(
        title: 'New message',
        body: 'Alex sent you a message',
        data: {
          'type': 'message',
          'user_name': 'Alex',
          'message_preview': 'Hello there',
          'conversation_id': '44',
        },
      );
      expect(copy.title, 'Alex');
      expect(copy.body, 'Hello there');
      expect(
        BackgroundMessageDisplay.messageGroupKey({
          'type': 'message',
          'conversation_id': '44',
        }),
        'messages_44',
      );
    });

    test('redacted chat keeps the generic tray copy', () {
      final copy = BackgroundMessageDisplay.chatTrayCopy(
        title: 'New message',
        body: 'You have a new message. Upgrade to read it.',
        data: {
          'type': 'message',
          'user_name': 'Alex',
          'message_preview': 'secret',
          'content_redacted': '1',
        },
      );
      expect(copy.title, 'New message');
      expect(copy.body, 'You have a new message. Upgrade to read it.');
    });

    test('likes, matches, calls, and messages use their own channels', () {
      expect(notificationChannelIdFor('like'), kLgbtfinderLikesChannelId);
      expect(notificationChannelIdFor('superlike'), kLgbtfinderLikesChannelId);
      expect(notificationChannelIdFor('match'), kLgbtfinderMatchesChannelId);
      expect(notificationChannelIdFor('missed_call'), kLgbtfinderCallsChannelId);
      expect(notificationChannelIdFor('message'), kLgbtfinderMessagesChannelId);
      expect(notificationChannelLabel(kLgbtfinderLikesChannelId), 'Likes');
      expect(notificationChannelLabel(kLgbtfinderMatchesChannelId), 'Matches');
    });

    test(
      'data-only chat posts a local notification in the background isolate',
      () {
        expect(
          BackgroundMessageDisplay.shouldPostLocalNotification(
            hasOsNotificationPayload: false,
            isCallPayload: false,
          ),
          isTrue,
        );
      },
    );

    test('an OS notification payload is not posted again locally', () {
      expect(
        BackgroundMessageDisplay.shouldPostLocalNotification(
          hasOsNotificationPayload: true,
          isCallPayload: false,
        ),
        isFalse,
      );
    });

    test('call payloads stay with CallKit', () {
      expect(
        BackgroundMessageDisplay.shouldPostLocalNotification(
          hasOsNotificationPayload: false,
          isCallPayload: true,
        ),
        isFalse,
      );
    });

    test('a shade row that already shows this message is not posted again', () {
      const active = [
        BackgroundTrayItem(
          id: 7,
          tag: 'FCM-Notification:1',
          title: 'New Message! 💬',
          body: 'Abolfazl Najafi sent you a message',
        ),
      ];
      expect(
        BackgroundMessageDisplay.trayAlreadyShowsMessage(
          title: 'New Message! 💬',
          body: 'Abolfazl Najafi sent you a message',
          active: active,
        ),
        isTrue,
      );
      expect(
        BackgroundMessageDisplay.shouldPostLocalNotification(
          hasOsNotificationPayload: false,
          isCallPayload: false,
          trayAlreadyShowsMessage: true,
        ),
        isFalse,
      );
    });

    test('keeps one tray row and drops the duplicate', () {
      const local = BackgroundTrayItem(
        id: 11,
        tag: 'lgbtfinder-message-11',
        title: 'New Message! 💬',
        body: 'Abolfazl Najafi sent you a message',
      );
      const system = BackgroundTrayItem(
        id: 99,
        tag: 'FCM-Notification:99',
        title: 'New Message! 💬',
        body: 'Abolfazl Najafi sent you a message',
      );
      final extras = BackgroundMessageDisplay.extrasToCancel(
        title: local.title!,
        body: local.body!,
        keepTag: local.tag!,
        active: const [system, local],
      );
      expect(extras, [system]);
      expect(
        BackgroundMessageDisplay.extrasToCancel(
          title: local.title!,
          body: local.body!,
          keepTag: local.tag!,
          active: const [local],
        ),
        isEmpty,
      );
    });

    test('message tag is stable for one chat message id', () {
      expect(
        BackgroundMessageDisplay.trayTagForMessage(42),
        'lgbtfinder-message-42',
      );
      expect(
        BackgroundMessageDisplay.trayTagForMessage(42),
        BackgroundMessageDisplay.trayTagForMessage('42'),
      );
    });

    test('resolves the tray text from the data payload', () {
      final text = BackgroundMessageDisplay.resolveText(
        data: {'type': 'message', 'title': 'Abolfazl', 'body': 'RT test 3'},
      );
      expect(text?.title, 'Abolfazl');
      expect(text?.body, 'RT test 3');
    });

    test(
      'falls back to sender name and preview when title or body is absent',
      () {
        final text = BackgroundMessageDisplay.resolveText(
          data: {
            'type': 'message',
            'user_name': 'Abolfazl',
            'message_preview': 'RT test 4',
          },
        );
        expect(text?.title, 'Abolfazl');
        expect(text?.body, 'RT test 4');
      },
    );

    test('returns null when there is nothing to show', () {
      expect(
        BackgroundMessageDisplay.resolveText(data: {'type': 'message'}),
        isNull,
      );
    });

    test('message channel id matches the backend FCM channel', () {
      expect(kLgbtfinderMessagesChannelId, 'lgbtfinder_messages');
      expect(kLgbtfinderFcmChannelId, 'lgbtfinder_channel');
    });
  });
}
