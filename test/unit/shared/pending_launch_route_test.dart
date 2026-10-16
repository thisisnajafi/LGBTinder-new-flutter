import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/shared/services/notification_navigation.dart';
import 'package:lgbtindernew/shared/services/pending_launch_route.dart';
import 'package:lgbtindernew/pages/splash_page.dart';

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
