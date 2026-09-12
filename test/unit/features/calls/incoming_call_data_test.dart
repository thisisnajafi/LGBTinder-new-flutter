import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/incoming_call_data.dart';
import 'package:lgbtindernew/features/calls/utils/call_navigation.dart';
import 'package:lgbtindernew/routes/app_router.dart';

void main() {
  group('IncomingCallData.callIdFromPayload', () {
    test('reads call_id from a flat pusher payload', () {
      expect(
        IncomingCallData.callIdFromPayload({'call_id': 42, 'status': 'ended'}),
        '42',
      );
    });

    test('reads nested data.call_id', () {
      expect(
        IncomingCallData.callIdFromPayload({
          'data': {'callId': '99'},
        }),
        '99',
      );
    });

    test('returns null when missing', () {
      expect(IncomingCallData.callIdFromPayload({'status': 'ended'}), isNull);
    });
  });

  group('IncomingCallData.isCallPayload', () {
    test('treats incoming_call as a live call', () {
      expect(
        IncomingCallData.isCallPayload({'type': 'incoming_call', 'call_id': 1}),
        isTrue,
      );
    });

    test('does not treat missed_call FCM as a live incoming call', () {
      expect(
        IncomingCallData.isCallPayload({
          'type': 'missed_call',
          'call_id': 9,
        }),
        isFalse,
      );
    });

    test('does not treat like or chat FCM as a live incoming call', () {
      expect(
        IncomingCallData.isCallPayload({
          'type': 'like',
          'call_id': 9,
          'caller_id': 2,
          'call_type': 'audio',
        }),
        isFalse,
      );
      expect(
        IncomingCallData.isCallPayload({
          'type': 'message',
          'conversation_id': 3,
        }),
        isFalse,
      );
    });

    test('does not treat call_declined as a live incoming call', () {
      expect(
        IncomingCallData.isCallPayload({
          'type': 'call_declined',
          'call_id': 9,
        }),
        isFalse,
      );
    });
  });

  group('IncomingCallData.fromCallKitMap', () {
    test('reads extras from a CallKit accept body', () {
      final data = IncomingCallData.fromCallKitMap({
        'id': '55',
        'nameCaller': 'Alex',
        'avatar': 'https://cdn/a.png',
        'type': 1,
        'isAccepted': true,
        'extra': {
          'callId': '55',
          'callerId': 12,
          'callType': 'video',
          'callerName': 'Alex',
        },
      });

      expect(data, isNotNull);
      expect(data!.callId, '55');
      expect(data.callerId, 12);
      expect(data.isVideo, isTrue);
      expect(data.callerName, 'Alex');
    });

    test('falls back to nameCaller and type when extra is thin', () {
      final data = IncomingCallData.fromCallKitMap({
        'id': '8',
        'nameCaller': 'Sam',
        'type': 0,
        'extra': {'callerId': 3},
      });

      expect(data!.callId, '8');
      expect(data.callerId, 3);
      expect(data.isVideo, isFalse);
      expect(data.callerName, 'Sam');
    });

    test('restores agora_channel from extras', () {
      final data = IncomingCallData.fromCallKitMap({
        'id': '77',
        'nameCaller': 'Alex',
        'avatar': 'https://cdn.example/a.png',
        'type': 1,
        'isAccepted': true,
        'extra': {
          'callId': '77',
          'callerId': 5,
          'callType': 'video',
          'callerName': 'Alex',
          'callerAvatar': 'https://cdn.example/a.png',
          'agora_channel': 'call_5_9_1',
        },
      });

      expect(data!.callId, '77');
      expect(data.callType, 'video');
      expect(data.callerAvatar, 'https://cdn.example/a.png');
      expect(data.channelName, 'call_5_9_1');
    });
  });

  test('FCM payload round-trips call id, type, avatar, and agora channel', () {
    final data = IncomingCallData.fromPayload({
      'type': 'incoming_call_video',
      'call_id': '77',
      'caller_id': 5,
      'caller_name': 'Alex',
      'call_type': 'video',
      'caller_avatar': 'https://cdn.example/a.png',
      'agora_channel': 'call_5_9_1',
    });

    expect(data, isNotNull);
    expect(data!.callId, '77');
    expect(data.callType, 'video');
    expect(data.callerAvatar, 'https://cdn.example/a.png');
    expect(data.channelName, 'call_5_9_1');

    final restored = IncomingCallData.fromPayload(data.toExtras());
    expect(restored!.callId, '77');
    expect(restored.callType, 'video');
    expect(restored.callerAvatar, 'https://cdn.example/a.png');
    expect(restored.channelName, 'call_5_9_1');
    expect(data.toExtras()['agora_channel'], 'call_5_9_1');
  });

  test('activeCallLocationFromIncoming is the callee call route', () {
    final location = activeCallLocationFromIncoming(
      const IncomingCallData(
        callId: '9',
        callType: 'video',
        callerId: 4,
        callerName: 'Pat',
      ),
    );
    expect(location, startsWith(AppRoutes.outgoingCall));
    expect(location, contains('callee=1'));
    expect(location, contains('callId=9'));
  });
}
