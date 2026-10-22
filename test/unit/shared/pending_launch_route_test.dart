import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/shared/services/notification_navigation.dart';
import 'package:lgbtindernew/shared/services/pending_launch_route.dart';
import 'package:lgbtindernew/pages/splash_page.dart';
import 'package:notification_launch/notification_launch.dart';

void main() {
  setUp(PendingLaunchRoute.reset);

  test('local launch payload keeps the chat peer and call back action', () {
    final chat = PendingLaunchRoute.payloadFromLocalLaunch(
      didLaunchApp: true,
      payload: '{"type":"message","user_id":"12","sender_id":"12","message_id":"9"}',
    );
    expect(chat?['type'], 'message');
    expect(NotificationNavigation.resolvePeerUserId(chat!), 12);

    final callBack = PendingLaunchRoute.payloadFromLocalLaunch(
      didLaunchApp: true,
      payload: '{"type":"missed_call","user_id":4,"call_type":"video","user_name":"Alex"}',
      actionId: 'call_back',
    );
    expect(callBack?['action'], 'call_back');
    final route = NotificationNavigation.resolveDestination(
      type: 'missed_call',
      data: callBack!,
      peerUserId: 4,
    );
    expect(route, contains(AppRoutes.outgoingCall));
    expect(route, contains('initiate=1'));
    expect(route, contains('type=video'));
    expect(route, contains('recipientId=4'));
  });

  test('a notification that did not launch the app stores nothing', () {
    expect(
      PendingLaunchRoute.payloadFromLocalLaunch(
        didLaunchApp: false,
        payload: '{"type":"message","user_id":1}',
      ),
      isNull,
    );
  });

  test('fcm initial message maps chat to a thread and outranks a generic tap', () {
    final message = PendingLaunchRoute.payloadFromFcmData({
      'type': 'chat',
      'user_id': '8',
      'conversation_id': '3',
    });
    expect(message?['type'], 'message');

    PendingLaunchRoute.store({'type': 'like', 'user_id': 1});
    PendingLaunchRoute.store(message);
    expect(PendingLaunchRoute.peek()?['type'], 'message');
    expect(PendingLaunchRoute.peek()?['user_id'], '8');

    final location = locationForPendingLaunch(PendingLaunchRoute.consume());
    expect(location, contains('userId=8'));
    expect(location, contains(AppRoutes.chat));
    expect(location, isNot(contains('/discovery')));
  });

  test('call back outranks a chat tap from the same cold start', () {
    PendingLaunchRoute.store({
      'type': 'message',
      'user_id': 3,
    });
    PendingLaunchRoute.store(
      NotificationNavigation.callBackPayload(
        userId: 4,
        userName: 'Alex',
        callType: 'audio',
      ),
    );
    final pending = PendingLaunchRoute.consume();
    expect(pending?['action'], 'call_back');
    final location = locationForPendingLaunch(pending);
    expect(location, contains('type=voice'));
    expect(location, contains('initiate=1'));
  });

  test('splash ignores an empty pending route', () {
    expect(locationForPendingLaunch(null), isNull);
    expect(locationForPendingLaunch({'type': ''}), isNull);
  });

  test('authenticated splash opens the chat instead of dropping it on home', () {
    final location = locationForPendingLaunch({
      'type': 'message',
      'user_id': '12',
      'message_id': '9',
    });
    expect(routeAfterAuthenticatedSplash(null), AppRoutes.home);
    expect(routeAfterAuthenticatedSplash(location), contains('userId=12'));
    expect(routeAfterAuthenticatedSplash(location), isNot(AppRoutes.home));

    PendingLaunchRoute.arm(location);
    final decision = evaluateGuardDecision(
      location: AppRoutes.splash,
      hasLeftStartupFlow: true,
      authStage: AuthStage.authenticated,
      isPublicRoute: true,
      isAuthEntryRoute: false,
      isProtectedRoute: false,
      hasPendingProtectedRoute: false,
      launchRoute: PendingLaunchRoute.peekArmed(),
    );
    expect(decision.redirectTo, contains('userId=12'));
    expect(PendingLaunchRoute.peekArmed(), contains('userId=12'));
  });

  test('a second launch read of the same tap is ignored', () {
    final payload = {'type': 'message', 'user_id': 5, 'message_id': 1};
    PendingLaunchRoute.storeLaunch(payload);
    PendingLaunchRoute.storeLaunch(Map<String, dynamic>.from(payload));
    expect(PendingLaunchRoute.peek()?['message_id'], 1);
    PendingLaunchRoute.consume();
    PendingLaunchRoute.storeLaunch(Map<String, dynamic>.from(payload));
    expect(PendingLaunchRoute.hasPayload, isFalse);
  });

  test('notification tap request codes stay unique per tag', () {
    expect(notificationLaunchRequestCode(7, null), 7);
    expect(notificationLaunchRequestCode(7, ''), 7);
    expect(
      notificationLaunchRequestCode(7, 'lgbtfinder-message-4'),
      isNot(notificationLaunchRequestCode(7, 'lgbtfinder-message-8')),
    );
    expect(
      notificationLaunchRequestCode(7, 'lgbtfinder-message-4'),
      notificationLaunchRequestCode(7, 'lgbtfinder-message-4'),
    );
  });

  test('a consumed launch is not stored again immediately', () {
    PendingLaunchRoute.store({'type': 'message', 'user_id': 5, 'message_id': 1});
    PendingLaunchRoute.consume();
    PendingLaunchRoute.store({'type': 'message', 'user_id': 5, 'message_id': 1});
    expect(PendingLaunchRoute.hasPayload, isFalse);
    expect(
      PendingLaunchRoute.wasJustConsumed({
        'type': 'message',
        'user_id': 5,
        'message_id': 1,
      }),
      isTrue,
    );
  });
}
