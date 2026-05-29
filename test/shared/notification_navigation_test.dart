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

    test('match opens chat thread when peer id known', () {
      final route = NotificationNavigation.resolveDestination(
        type: 'match',
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

    test('message push payload opens chat', () {
      expect(
        NotificationNavigation.resolveDestination(
          type: 'message',
          data: {'user_id': 5, 'sender_id': 5},
        ),
        Uri(path: AppRoutes.chat, queryParameters: {'userId': '5'}).toString(),
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
  });
}
