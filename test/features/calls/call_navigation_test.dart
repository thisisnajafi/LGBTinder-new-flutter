import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/models/active_call_session.dart';
import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/utils/call_navigation.dart';
import 'package:lgbtindernew/routes/app_router.dart';

void main() {
  group('activeCallLocationFromIncoming', () {
    test('builds callee outgoing-call location', () {
      final data = IncomingCallData(
        callId: '99',
        callType: 'audio',
        callerId: 3,
        callerName: 'Peer',
      );
      final loc = activeCallLocationFromIncoming(data);
      expect(loc, contains(AppRoutes.outgoingCall));
      expect(loc, contains('callId=99'));
      expect(loc, contains('callee=1'));
      expect(loc, contains('type=voice'));
    });
  });

  group('ActiveCallSession.routeLocation', () {
    test('matches callee outgoing location', () {
      const session = ActiveCallSession(
        callId: 99,
        peerId: 3,
        peerName: 'Peer',
        isVideo: false,
      );
      expect(session.routeLocation, contains(AppRoutes.outgoingCall));
      expect(session.routeLocation, contains('callId=99'));
      expect(session.routeLocation, contains('callee=1'));
    });
  });
}
