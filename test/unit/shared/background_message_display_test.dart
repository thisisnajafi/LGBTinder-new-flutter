import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/services/background_message_display.dart';

void main() {
  group('BackgroundMessageDisplay', () {
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
