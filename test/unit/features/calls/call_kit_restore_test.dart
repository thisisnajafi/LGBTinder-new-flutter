import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call_kit_restore.dart';

void main() {
  group('CallKitRestore', () {
    test('picks the newest accepted call and keeps extras', () {
      final picked = CallKitRestore.pick([
        {
          'id': '10',
          'isAccepted': false,
          'extra': {
            'callId': '10',
            'callerId': 1,
            'callType': 'audio',
            'callerName': 'Old',
          },
        },
        {
          'id': '77',
          'isAccepted': true,
          'nameCaller': 'Alex',
          'avatar': 'https://cdn.example/a.png',
          'type': 1,
          'extra': {
            'callId': '77',
            'callerId': 5,
            'callType': 'video',
            'callerName': 'Alex',
            'callerAvatar': 'https://cdn.example/a.png',
            'agora_channel': 'call_5_9_1',
          },
        },
        {
          'id': '12',
          'accepted': true,
          'extra': {
            'callId': '12',
            'callerId': 2,
            'callType': 'audio',
            'callerName': 'Sam',
          },
        },
      ]);

      expect(picked.accepted, isNotNull);
      expect(picked.accepted!.callId, '77');
      expect(picked.accepted!.callType, 'video');
      expect(picked.accepted!.callerAvatar, 'https://cdn.example/a.png');
      expect(picked.accepted!.channelName, 'call_5_9_1');
      expect(picked.ringing, isNull);
      expect(picked.staleIds, containsAll(['10', '12']));
    });

    test('keeps the newest unanswered call ringing', () {
      final picked = CallKitRestore.pick([
        {
          'id': '10',
          'isAccepted': false,
          'extra': {
            'callId': '10',
            'callerId': 1,
            'callType': 'audio',
            'callerName': 'Old',
          },
        },
        {
          'id': '14',
          'isAccepted': false,
          'extra': {
            'callId': '14',
            'callerId': 3,
            'callType': 'video',
            'callerName': 'Riley',
          },
        },
      ]);
      expect(picked.accepted, isNull);
      expect(picked.ringing, isNotNull);
      expect(picked.ringing!.callId, '14');
      expect(picked.staleIds, ['10']);
    });
  });
}
