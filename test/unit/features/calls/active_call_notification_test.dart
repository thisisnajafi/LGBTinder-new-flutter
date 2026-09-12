import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/active_call_notification.dart';

void main() {
  group('ActiveCallNotification', () {
    test('encode/decode round-trips call id and location', () {
      final raw = ActiveCallNotification.encode(
        callId: 42,
        location: '/call/outgoing?callId=42',
        peerName: 'Alex',
      );
      final decoded = ActiveCallNotification.decode(raw);
      expect(decoded, isNotNull);
      expect(decoded!['type'], ActiveCallNotification.type);
      expect(decoded['call_id'], '42');
      expect(decoded['location'], '/call/outgoing?callId=42');
      expect(decoded['peer_name'], 'Alex');
    });

    test('title is Active call with {name}', () {
      expect(
        ActiveCallNotification.titleFor('Alex'),
        'Active call with Alex',
      );
    });

    test('hang-up action is distinct from a body tap', () {
      expect(
        ActiveCallNotification.isHangupAction(
          ActiveCallNotification.actionHangup,
        ),
        isTrue,
      );
      expect(
        ActiveCallNotification.isReturnAction(
          ActiveCallNotification.actionHangup,
          null,
        ),
        isFalse,
      );
    });

    test('body tap with payload is a return action', () {
      final raw = ActiveCallNotification.encode(
        callId: 1,
        location: '/call/outgoing?callId=1',
        peerName: 'Sam',
      );
      expect(ActiveCallNotification.isReturnAction(null, raw), isTrue);
      expect(
        ActiveCallNotification.isReturnAction(
          ActiveCallNotification.actionReturn,
          raw,
        ),
        isTrue,
      );
    });

    test('decode rejects unrelated payloads', () {
      expect(ActiveCallNotification.decode('{"type":"like"}'), isNull);
      expect(ActiveCallNotification.decode('not-json'), isNull);
    });
  });

  group('ActiveCallBridge', () {
    tearDown(() {
      ActiveCallBridge.handle = null;
      ActiveCallBridge.pendingActionId = null;
      ActiveCallBridge.pendingPayload = null;
    });

    test('queues until a handler is attached', () {
      String? seenAction;
      ActiveCallBridge.dispatch(ActiveCallNotification.actionHangup, '{}');
      expect(ActiveCallBridge.pendingActionId, ActiveCallNotification.actionHangup);

      ActiveCallBridge.handle = (actionId, payload) {
        seenAction = actionId;
      };
      ActiveCallBridge.consumePending();
      expect(seenAction, ActiveCallNotification.actionHangup);
      expect(ActiveCallBridge.pendingActionId, isNull);
    });
  });
}
