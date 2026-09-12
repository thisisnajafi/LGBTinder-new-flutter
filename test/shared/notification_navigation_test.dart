import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/notifications/data/models/notification.dart' as app_models;
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/shared/services/notification_navigation.dart';

void main() {
  group('NotificationNavigation', () {
    test('resolvePeerUserId reads user_id and sender_id', () {
      expect(
        NotificationNavigation.resolvePeerUserId({'user_id': 42}),
        42,
      );
      expect(
        NotificationNavigation.resolvePeerUserId({'sender_id': '7'}),
        7,
      );
    });

    test('resolvePeerUserId reads nested data map', () {
      expect(
        NotificationNavigation.resolvePeerUserId({
          'type': 'match',
          'data': {'user_id': 99},
        }),
        99,
      );
    });

    test('normalizePayload maps chat type to message', () {
      final normalized = NotificationNavigation.normalizePayload({'type': 'chat'});
      expect(normalized['type'], 'message');
    });

    test('match always opens matches list even when peer id known', () {
      final route = NotificationNavigation.resolveDestination(
        type: 'match',
        peerUserId: 12,
        userName: 'Alex',
      );
      expect(route, '${AppRoutes.home}/matches');
    });

    test('superlike opens chat when peer id known', () {
      final route = NotificationNavigation.resolveDestination(
        type: 'superlike',
        peerUserId: 12,
        userName: 'Alex',
      );
      expect(
        route,
        Uri(
          path: AppRoutes.chat,
          queryParameters: {'userId': '12', 'userName': 'Alex'},
        ).toString(),
      );
    });

    test('superlike without user id goes to discovery', () {
      expect(
        NotificationNavigation.resolveDestination(type: 'superlike'),
        '${AppRoutes.home}/discovery',
      );
    });

    test('plan restricted without user id goes to feature locked', () {
      expect(
        NotificationNavigation.resolveDestination(
          type: 'superlike',
          planRestricted: true,
        ),
        AppRoutes.featureLocked,
      );
    });

    test('incoming_call opens the live call page not chat', () {
      final route = NotificationNavigation.resolveDestination(
        type: 'incoming_call',
        data: {
          'call_id': 77,
          'caller_id': 12,
          'caller_name': 'Alex',
          'call_type': 'video',
        },
      );
      expect(route, startsWith(AppRoutes.outgoingCall));
      expect(route, contains('callId=77'));
      expect(route, contains('recipientId=12'));
      expect(route, contains('callee=1'));
      expect(route, isNot(contains(AppRoutes.chat)));
    });

    test('incoming_call without payload goes home not chat', () {
      expect(
        NotificationNavigation.resolveDestination(type: 'incoming_call'),
        AppRoutes.home,
      );
    });

    test('message push payload opens chat', () {
      expect(
        NotificationNavigation.resolveDestination(
          type: 'message',
          data: {'user_id': 5, 'sender_id': 5},
        ),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '5'}).toString(),
      );
    });

    test('resolveFromNotification match goes to matches list', () {
      final notification = app_models.Notification.fromJson({
        'id': 2,
        'type': 'match',
        'message': 'New match!',
        'created_at': DateTime.now().toIso8601String(),
        'from_user': {'id': 12, 'name': 'Alex'},
      });

      expect(
        NotificationNavigation.resolveFromNotification(notification),
        '${AppRoutes.home}/matches',
      );
    });

    test('resolveFromNotification uses from_user id', () {
      final notification = app_models.Notification.fromJson({
        'id': 1,
        'type': 'message',
        'message': 'Hi',
        'created_at': DateTime.now().toIso8601String(),
        'from_user': {'id': 33, 'name': 'Sam', 'avatar': 'https://x/a.png'},
      });

      final route = NotificationNavigation.resolveFromNotification(notification);
      expect(route, contains('userId=33'));
      expect(route, contains('userName=Sam'));
    });

    test('parseLocalNotificationPayload decodes JSON', () {
      final parsed = NotificationNavigation.parseLocalNotificationPayload(
        '{"type":"match","user_id":8}',
      );
      expect(parsed?['type'], 'match');
      expect(parsed?['user_id'], 8);
    });

    test('profile visit aliases open the peer profile', () {
      for (final type in ['view', 'visit', 'profile_visit', 'profile_view']) {
        expect(
          NotificationNavigation.resolveDestination(
            type: type,
            peerUserId: 9,
          ),
          Uri(path: AppRoutes.profileDetail, queryParameters: {'userId': '9'})
              .toString(),
        );
      }
    });

    test('missed call opens peer call history', () {
      expect(
        NotificationNavigation.resolveDestination(
          type: 'missed_call',
          peerUserId: 4,
        ),
        Uri(path: AppRoutes.peerCallHistory, queryParameters: {'userId': '4'})
            .toString(),
      );
    });

    test('plan and verification types have explicit destinations', () {
      expect(
        NotificationNavigation.resolveDestination(type: 'plan_downgraded'),
        AppRoutes.subscriptionManagement,
      );
      expect(
        NotificationNavigation.resolveDestination(type: 'superlike_pack_purchased'),
        AppRoutes.superlikePacks,
      );
      expect(
        NotificationNavigation.resolveDestination(type: 'verification_approved'),
        AppRoutes.profileVerification,
      );
      expect(
        NotificationNavigation.resolveDestination(type: 'safety_alert'),
        '${AppRoutes.home}/safety-center',
      );
      expect(
        NotificationNavigation.resolveDestination(type: 'promo'),
        AppRoutes.subscriptionPlans,
      );
    });

    test('unknown type opens the notifications tab', () {
      expect(
        NotificationNavigation.resolveDestination(type: 'totally_unknown'),
        '${AppRoutes.home}/notifications',
      );
    });
  });
}
