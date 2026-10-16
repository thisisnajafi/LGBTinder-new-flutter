import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/notifications/data/foreground_push_policy.dart';
import 'package:lgbtindernew/shared/services/background_message_display.dart';
import 'package:lgbtindernew/shared/services/notification_payload_map.dart';

void main() {
  group('NotificationPayloadMap', () {
    test('message uses the messages channel, preview, and reply actions', () {
      final mapped = MappedTrayNotification.from(
        data: {
          'type': 'message',
          'title': 'New message',
          'body': 'Alex sent you a message',
          'sender_name': 'Alex',
          'sender_id': '7',
          'user_id': '7',
          'conversation_id': '44',
          'message_id': '90',
          'message_preview': 'Hello there',
          'avatar_url': 'https://cdn.example/notification-avatars/blur.jpg',
          'caller_avatar': 'https://cdn.example/profiles/clear.jpg',
        },
      );

      expect(mapped, isNotNull);
      expect(mapped!.channelId, kLgbtfinderMessagesChannelId);
      expect(mapped.title, 'Alex');
      expect(mapped.body, 'Hello there');
      expect(mapped.style, TrayStyleKind.messaging);
      expect(mapped.groupKey, 'messages_44');
      expect(mapped.tag, 'lgbtfinder-message-90');
      expect(mapped.reply, isTrue);
      expect(mapped.markRead, isTrue);
      expect(mapped.callBack, isFalse);
      expect(
        mapped.avatarUrl,
        'https://cdn.example/notification-avatars/blur.jpg',
      );
    });

    test('like and super like use the likes channel and the payload avatar', () {
      final like = MappedTrayNotification.from(
        data: {
          'type': 'like',
          'title': 'New like',
          'body': 'Alex liked you',
          'user_id': '7',
          'avatar_url': 'https://cdn.example/notification-avatars/like.jpg',
        },
      );
      final superLike = MappedTrayNotification.from(
        data: {
          'type': 'super_like',
          'title': 'Super Like',
          'body': 'Alex sent you a Super Like',
          'sender_id': '8',
          'avatar_url': 'https://cdn.example/notification-avatars/super.jpg',
        },
      );

      expect(like!.channelId, kLgbtfinderLikesChannelId);
      expect(like.style, TrayStyleKind.bigText);
      expect(like.reply, isFalse);
      expect(like.avatarUrl, 'https://cdn.example/notification-avatars/like.jpg');
      expect(like.tag, 'lgbtfinder-like-7');

      expect(superLike!.type, 'superlike');
      expect(superLike.channelId, kLgbtfinderLikesChannelId);
      expect(superLike.title, 'Super Like');
      expect(
        superLike.avatarUrl,
        'https://cdn.example/notification-avatars/super.jpg',
      );
    });

    test('match uses the matches channel', () {
      final mapped = MappedTrayNotification.from(
        data: {
          'type': 'match',
          'title': "It's a match",
          'body': 'You and Alex matched. Say hello.',
          'user_id': '9',
          'avatar_url': 'https://cdn.example/notification-avatars/match.jpg',
        },
      );

      expect(mapped!.channelId, kLgbtfinderMatchesChannelId);
      expect(mapped.title, "It's a match");
      expect(mapped.avatarUrl, 'https://cdn.example/notification-avatars/match.jpg');
      expect(mapped.reply, isFalse);
    });

    test('missed call uses the calls channel and call back', () {
      final mapped = MappedTrayNotification.from(
        data: {
          'type': 'missed_call',
          'title': 'Missed call',
          'body': 'You missed a video call from Alex',
          'user_id': '4',
          'call_id': '15',
          'call_kind': 'video',
          'avatar_url': 'https://cdn.example/notification-avatars/call.jpg',
        },
      );

      expect(mapped!.channelId, kLgbtfinderCallsChannelId);
      expect(mapped.callBack, isTrue);
      expect(mapped.reply, isFalse);
      expect(mapped.tag, 'lgbtfinder-missed_call-15');
      expect(mapped.avatarUrl, 'https://cdn.example/notification-avatars/call.jpg');
    });

    test('a clear url that is not avatar_url is not fetched', () {
      final mapped = MappedTrayNotification.from(
        data: {
          'type': 'like',
          'title': 'New like',
          'body': 'Someone liked you',
          'caller_avatar': 'https://cdn.example/profiles/clear.jpg',
          'primary_image_url': 'https://cdn.example/profiles/clear.jpg',
        },
      );

      expect(mapped!.avatarUrl, isNull);
    });

    test('foreground keeps the mapping but does not add a tray row', () {
      final mapped = MappedTrayNotification.from(
        data: {
          'type': 'message',
          'title': 'Alex',
          'body': 'Hello',
          'message_id': '3',
        },
      );

      expect(mapped, isNotNull);
      expect(
        ForegroundPushPolicy.shouldShowDeviceNotification(
          appForeground: true,
          isIncomingCall: false,
        ),
        isFalse,
      );
      expect(
        BackgroundMessageDisplay.shouldPostLocalNotification(
          hasOsNotificationPayload: false,
          isCallPayload: false,
        ),
        isTrue,
      );
    });

    test('an OS alert is not posted again as a local notification', () {
      expect(
        BackgroundMessageDisplay.shouldPostLocalNotification(
          hasOsNotificationPayload: true,
          isCallPayload: false,
        ),
        isFalse,
      );
    });
  });
}
