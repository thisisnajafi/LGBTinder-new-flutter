import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/services/app_logger.dart';
import 'package:lgbtindernew/features/calls/utils/call_signaling_log.dart';
import 'package:lgbtindernew/shared/services/chat_pusher_event_names.dart';

void main() {
  group('CallSignalingLog', () {
    test('covers all five Pusher call event names with call_id', () {
      const names = [
        ChatPusherEventNames.callIncoming,
        ChatPusherEventNames.callAccepted,
        ChatPusherEventNames.callRejected,
        ChatPusherEventNames.callEnded,
        ChatPusherEventNames.callBusy,
      ];
      expect(CallSignalingLog.eventNames, names);

      for (final name in names) {
        final line = CallSignalingLog.eventLineFromPayload(name, {
          'call_id': 77,
          'caller_id': 12,
        });
        expect(line, 'Call event: $name from user 12 call_id=77');
        expect(CallSignalingLog.isCallEvent(name), isTrue);
      }
    });

    test('reads nested payload call_id and caller map', () {
      final line = CallSignalingLog.eventLineFromPayload(
        ChatPusherEventNames.callAccepted,
        {
          'data': {
            'callId': '9',
            'caller': {'id': 4},
          },
        },
      );
      expect(line, contains('call.accepted'));
      expect(line, contains('from user 4'));
      expect(line, contains('call_id=9'));
    });

    test('HTTP success and error lines include the action and call_id', () {
      expect(
        CallSignalingLog.httpSuccess('initiate', '15'),
        'HTTP initiate ok call_id=15',
      );
      expect(
        CallSignalingLog.httpError('reject', '15'),
        'HTTP reject failed call_id=15',
      );
      for (final action in ['initiate', 'accept', 'reject', 'end', 'busy']) {
        expect(CallSignalingLog.httpError(action, '1'), contains(action));
        expect(CallSignalingLog.httpError(action, '1'), contains('call_id=1'));
      }
    });
  });

  test('CallSignaling tag floor is info so event lines show in debug', () {
    expect(AppLogger.minLevelFor(CallSignalingLog.tag), LogLevel.info);
    expect(
      LogLevel.info.index >= AppLogger.minLevelFor(CallSignalingLog.tag).index,
      isTrue,
    );
  });
}
