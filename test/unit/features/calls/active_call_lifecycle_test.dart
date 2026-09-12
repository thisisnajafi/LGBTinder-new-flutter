import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/active_call_session.dart';
import 'package:lgbtindernew/routes/app_router.dart';

void main() {
  group('ActiveCallLifecycle.keepEngine', () {
    test('keeps Agora when minimized and the call is still live', () {
      expect(
        ActiveCallLifecycle.keepEngine(callEnded: false, minimized: true),
        isTrue,
      );
    });

    test('releases Agora after hang-up even if minimized was set', () {
      expect(
        ActiveCallLifecycle.keepEngine(callEnded: true, minimized: true),
        isFalse,
      );
    });
  });

  group('ActiveCallLifecycle.shouldSkipJoin', () {
    test('skips join when already in the same channel', () {
      expect(
        ActiveCallLifecycle.shouldSkipJoin(
          agoraInCall: true,
          engineChannelId: 'ch-1',
          sessionChannelId: 'ch-1',
          sessionJoined: true,
        ),
        isTrue,
      );
    });

    test('does not skip when the engine is idle', () {
      expect(
        ActiveCallLifecycle.shouldSkipJoin(
          agoraInCall: false,
          engineChannelId: null,
          sessionChannelId: 'ch-1',
          sessionJoined: false,
        ),
        isFalse,
      );
    });

    test('does not skip when the channel changed', () {
      expect(
        ActiveCallLifecycle.shouldSkipJoin(
          agoraInCall: true,
          engineChannelId: 'ch-1',
          sessionChannelId: 'ch-2',
          sessionJoined: true,
        ),
        isFalse,
      );
    });
  });

  group('ActiveCallLifecycle.shouldResume', () {
    const session = ActiveCallSession(
      callId: 42,
      peerId: 7,
      peerName: 'Alex',
      isVideo: false,
      agoraJoined: true,
      minimized: true,
    );

    test('resumes the matching minimized session', () {
      expect(
        ActiveCallLifecycle.shouldResume(
          pageCallId: 42,
          session: session,
          agoraInCall: true,
        ),
        isTrue,
      );
    });

    test('ignores a different call id', () {
      expect(
        ActiveCallLifecycle.shouldResume(
          pageCallId: 99,
          session: session,
          agoraInCall: true,
        ),
        isFalse,
      );
    });
  });

  group('ActiveCallLifecycle.isCurrentCallRoute', () {
    test('matches outgoing call path and callId', () {
      expect(
        ActiveCallLifecycle.isCurrentCallRoute(
          path: AppRoutes.outgoingCall,
          callIdQuery: '42',
          sessionCallId: 42,
        ),
        isTrue,
      );
    });

    test('rejects a different call', () {
      expect(
        ActiveCallLifecycle.isCurrentCallRoute(
          path: AppRoutes.outgoingCall,
          callIdQuery: '1',
          sessionCallId: 42,
        ),
        isFalse,
      );
    });
  });

  test('ActiveCallSession route includes callee and call id', () {
    const session = ActiveCallSession(
      callId: 42,
      peerId: 7,
      peerName: 'Alex',
      isVideo: true,
    );
    expect(session.routeLocation, contains(AppRoutes.outgoingCall));
    expect(session.routeLocation, contains('callId=42'));
    expect(session.routeLocation, contains('callee=1'));
    expect(session.routeLocation, contains('type=video'));
  });
}
