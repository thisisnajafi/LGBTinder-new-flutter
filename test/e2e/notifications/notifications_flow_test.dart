import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lgbtindernew/features/notifications/data/models/notification.dart'
    as app_models;
import 'package:lgbtindernew/features/notifications/data/services/notification_service.dart';
import 'package:lgbtindernew/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:lgbtindernew/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:lgbtindernew/features/notifications/providers/notification_providers.dart';
import 'package:lgbtindernew/pages/home_page.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/widgets/badges/notification_badge.dart';
import 'package:lgbtindernew/widgets/error_handling/empty_state.dart';
import 'package:lgbtindernew/widgets/loading/skeleton_loading.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_bootstrap.dart';

class MockNotificationService extends Mock implements NotificationService {}

app_models.Notification sampleNotification({
  required int id,
  String type = 'message',
  bool isRead = false,
  int? userId = 42,
  String? title,
  String? message,
  String? actionUrl,
}) {
  return app_models.Notification(
    id: id,
    type: type,
    title: title ?? 'Notification $id',
    message: message ?? 'Body $id',
    createdAt: DateTime.now(),
    isRead: isRead,
    userId: userId,
    actionUrl: actionUrl,
  );
}

Widget notificationsTestApp({
  required MockNotificationService notifications,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: MaterialApp(home: child),
  );
}

Future<void> pumpNotificationsScreen(
  WidgetTester tester,
  MockNotificationService notifications,
) async {
  await tester.pumpWidget(
    notificationsTestApp(
      notifications: notifications,
      child: const NotificationsScreen(),
    ),
  );
  await e2ePumpFrames(tester, frames: 6);
}

void stubNotificationPages(MockNotificationService notifications) {
  when(
    () => notifications.getNotifications(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
      unreadOnly: any(named: 'unreadOnly'),
    ),
  ).thenAnswer((invocation) async {
    final page = invocation.namedArguments[#page] as int? ?? 1;
    if (page == 1) {
      return List.generate(
        20,
        (i) => sampleNotification(id: i + 1, title: 'Page1-$i'),
      );
    }
    if (page == 2) {
      return [sampleNotification(id: 21, title: 'Page2-unique')];
    }
    return <app_models.Notification>[];
  });
}

/// Notifications tab flows (TEST-076 – TEST-083).
void main() {
  setUpAll(() {
    registerFallbackValue(1);
    registerFallbackValue(false);
  });

  late MockNotificationService notifications;

  setUp(() {
    notifications = MockNotificationService();
  });

  group('Notifications list', () {
    // TEST-076
    testWidgets('TEST-076: notifications tab renders first page', (tester) async {
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => [
          sampleNotification(id: 1, title: 'New match'),
          sampleNotification(id: 2, title: 'New message'),
        ],
      );

      await pumpNotificationsScreen(tester, notifications);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('New match'), findsOneWidget);
      expect(find.text('New message'), findsOneWidget);
    });

    // TEST-077
    testWidgets('TEST-077: scroll loads next page without duplicate ids', (tester) async {
      tester.view.physicalSize = const Size(1080, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => e2eResetViewport(tester));

      stubNotificationPages(notifications);

      await pumpNotificationsScreen(tester, notifications);

      expect(find.text('Page1-0'), findsOneWidget);

      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -800));
      await e2ePumpFrames(tester, frames: 8);
      await tester.drag(listFinder, const Offset(0, -800));
      await e2ePumpFrames(tester, frames: 8);

      expect(find.text('Page2-unique'), findsOneWidget);
      verify(
        () => notifications.getNotifications(
          page: 2,
          limit: 20,
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).called(greaterThanOrEqualTo(1));

      final titles = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .whereType<String>()
          .where((t) => t.startsWith('Page1-') || t.startsWith('Page2-'))
          .toList();
      expect(titles.toSet().length, titles.length);
    });

    // TEST-082
    testWidgets('TEST-082: empty notifications shows discovery CTAs', (tester) async {
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer((_) async => []);

      await pumpNotificationsScreen(tester, notifications);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text('Go to discovery'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
    });
  });

  group('Notification actions', () {
    // TEST-078
    testWidgets('TEST-078: tapping unread notification marks it read', (tester) async {
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => [
          sampleNotification(
            id: 7,
            type: 'promo',
            title: 'Unread ping',
            isRead: false,
          ),
        ],
      );
      when(() => notifications.markAsRead(7)).thenAnswer((_) async {});

      await pumpNotificationsScreen(tester, notifications);

      expect(find.byType(NotificationTile), findsOneWidget);
      await tester.tap(find.text('Unread ping'));
      await e2ePumpFrames(tester, frames: 4);

      verify(() => notifications.markAsRead(7)).called(1);
      expect(find.text('Mark all read'), findsNothing);
    });

    // TEST-079
    testWidgets('TEST-079: mark all read clears unread actions', (tester) async {
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => [
          sampleNotification(id: 1, isRead: false),
          sampleNotification(id: 2, isRead: false),
        ],
      );
      when(() => notifications.markAllAsRead()).thenAnswer((_) async {});

      await pumpNotificationsScreen(tester, notifications);

      expect(find.text('Mark all read'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await e2ePumpFrames(tester, frames: 4);

      verify(() => notifications.markAllAsRead()).called(1);
      expect(find.text('Mark all read'), findsNothing);
    });

    // TEST-080
    testWidgets('TEST-080: swipe dismiss deletes notification', (tester) async {
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => [sampleNotification(id: 9, title: 'Delete me')],
      );
      when(() => notifications.deleteNotification(9)).thenAnswer((_) async {});

      await pumpNotificationsScreen(tester, notifications);

      await tester.drag(
        find.byKey(const Key('notification_9')),
        const Offset(-400, 0),
      );
      await e2ePumpFrames(tester, frames: 4);

      verify(() => notifications.deleteNotification(9)).called(1);
      expect(find.text('Delete me'), findsNothing);
    });
  });

  group('Notification routing', () {
    // TEST-081
    testWidgets('TEST-081: message notification opens chat route', (tester) async {
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer(
        (_) async => [
          sampleNotification(
            id: 3,
            type: 'message',
            title: 'Chat alert',
            userId: 99,
            isRead: true,
          ),
        ],
      );
      when(() => notifications.markAsRead(any())).thenAnswer((_) async {});

      final router = GoRouter(
        initialLocation: '${AppRoutes.home}/notifications',
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomePage(),
            routes: [
              GoRoute(
                path: 'notifications',
                builder: (_, __) => const NotificationsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.chat,
            builder: (_, state) => Scaffold(
              body: Text('Chat thread ${state.uri.queryParameters['userId']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notifications),
            unreadNotificationCountProvider.overrideWith((_) async => 0),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await e2ePumpFrames(tester, frames: 8);

      await tester.tap(find.text('Chat alert'));
      await e2ePumpFrames(tester, frames: 6);

      expect(find.text('Chat thread 99'), findsOneWidget);
    });
  });

  group('Home unread badge', () {
    // TEST-083
    testWidgets('TEST-083: unread count shows on home bottom nav', (tester) async {
      e2eSetPhoneViewport(tester);
      addTearDown(() => e2eResetViewport(tester));

      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer((_) async => []);
      when(() => notifications.getUnreadCount()).thenAnswer((_) async => 4);

      final router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomePage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notifications),
            unreadNotificationCountProvider.overrideWith((_) async => 4),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await e2ePumpFrames(tester, frames: 10);

      expect(find.byType(NotificationBadge), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NotificationBadge),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Loading state', () {
    testWidgets('TEST-076-loading: shows skeleton before data arrives', (tester) async {
      when(
        () => notifications.getNotifications(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          unreadOnly: any(named: 'unreadOnly'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return [sampleNotification(id: 1)];
      });

      await tester.pumpWidget(
        notificationsTestApp(
          notifications: notifications,
          child: const NotificationsScreen(),
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonLoading), findsOneWidget);

      await e2ePumpFrames(tester, frames: 4);
      expect(find.byType(NotificationTile), findsOneWidget);
    });
  });
}
