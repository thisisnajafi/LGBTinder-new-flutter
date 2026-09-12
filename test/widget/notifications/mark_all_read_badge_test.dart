import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/notifications/data/models/notification.dart'
    as app_models;
import 'package:lgbtindernew/features/notifications/data/services/notification_service.dart';
import 'package:lgbtindernew/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:lgbtindernew/features/notifications/providers/notification_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

app_models.Notification _unread({int id = 1}) {
  return app_models.Notification(
    id: id,
    type: 'like',
    title: 'New like',
    message: 'Someone liked you',
    createdAt: DateTime(2026, 1, 1),
    isRead: false,
  );
}

void main() {
  testWidgets(
    'leaving the notifications tab marks all read then clears the badge',
    (tester) async {
      final notifications = MockNotificationService();
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => app_models.NotificationsPageResult(
          notifications: [_unread()],
          unreadCount: 1,
        ),
      );
      when(() => notifications.getUnreadCount()).thenAnswer((_) async => 1);
      when(() => notifications.markAllAsRead()).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notifications),
          ],
          child: const MaterialApp(home: _LeaveNotificationsHost()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(NotificationsScreen)),
      );
      container.read(unreadNotificationCountSeedProvider.notifier).state = 1;
      expect(
        await container.read(unreadNotificationCountProvider.future),
        1,
      );

      await tester.tap(find.text('Leave'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => notifications.markAllAsRead()).called(1);
      expect(
        await container.read(unreadNotificationCountProvider.future),
        0,
      );
    },
  );
}

class _LeaveNotificationsHost extends StatefulWidget {
  const _LeaveNotificationsHost();

  @override
  State<_LeaveNotificationsHost> createState() =>
      _LeaveNotificationsHostState();
}

class _LeaveNotificationsHostState extends State<_LeaveNotificationsHost> {
  int _tab = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => setState(() => _tab = 0),
          child: const Text('Leave'),
        ),
        Expanded(
          child: NotificationsScreen(
            selectedTabIndex: _tab,
            notificationsTabIndex: 2,
          ),
        ),
      ],
    );
  }
}
