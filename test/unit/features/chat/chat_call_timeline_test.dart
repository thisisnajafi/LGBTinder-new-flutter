import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/chat/utils/chat_call_timeline.dart';

Call _call({
  required int id,
  required String status,
  int callerId = 1,
  int receiverId = 2,
}) {
  return Call(
    id: id,
    callId: id.toString(),
    callerId: callerId,
    receiverId: receiverId,
    callType: 'audio',
    status: status,
    startedAt: DateTime(2026, 5, 24, 10),
    endedAt: status == 'missed' ? DateTime(2026, 5, 24, 10, 0, 45) : null,
  );
}

Map<String, dynamic> _row(Call call) {
  return {
    'kind': 'call',
    'call_id': call.id,
    'status': call.status,
    'timestamp': call.timelineTimestamp,
    'call': call,
  };
}

void main() {
  group('ChatCallTimeline.upsert', () {
    test('inserts a missed call when the thread is empty', () {
      final missed = _call(id: 8, status: 'missed');
      final next = ChatCallTimeline.upsert(const [], _row(missed));

      expect(next, hasLength(1));
      expect(next.single['status'], 'missed');
      expect(next.single['call_id'], 8);
    });

    test('replaces a live row with missed instead of skipping', () {
      final ringing = _call(id: 8, status: 'ringing');
      final missed = _call(id: 8, status: 'missed');

      final next = ChatCallTimeline.upsert(
        ChatCallTimeline.upsert(const [], _row(ringing)),
        _row(missed),
      );

      expect(next.where((e) => e['kind'] == 'call'), hasLength(1));
      expect(next.single['status'], 'missed');
      expect((next.single['call'] as Call).status, 'missed');
    });

    test('does not let a lagging ringing GET overwrite missed', () {
      final missed = _call(id: 8, status: 'missed');
      final ringing = _call(id: 8, status: 'ringing');

      final next = ChatCallTimeline.upsert(
        ChatCallTimeline.upsert(const [], _row(missed)),
        _row(ringing),
      );

      expect(next, hasLength(1));
      expect(next.single['status'], 'missed');
    });
  });

  group('ChatCallTimeline.fromSignalingPayload', () {
    test('builds a missed call from call.ended', () {
      final call = ChatCallTimeline.fromSignalingPayload({
        'call_id': 12,
        'caller_id': 1,
        'receiver_id': 2,
        'call_type': 'video',
        'status': 'missed',
        'reason': 'Call not answered within 45 seconds',
      });

      expect(call, isNotNull);
      expect(call!.id, 12);
      expect(call.status, 'missed');
      expect(call.callType, 'video');
      expect(call.callerId, 1);
      expect(call.receiverId, 2);
    });

    test('ignores live ringing payloads', () {
      expect(
        ChatCallTimeline.fromSignalingPayload({
          'call_id': 12,
          'caller_id': 1,
          'receiver_id': 2,
          'status': 'ringing',
        }),
        isNull,
      );
    });
  });

  group('ChatCallTimeline.involvesThread', () {
    test('requires the peer and current user pair when both ids are known', () {
      final call = _call(id: 1, status: 'missed', callerId: 10, receiverId: 20);
      expect(
        ChatCallTimeline.involvesThread(
          call: call,
          peerUserId: 20,
          currentUserId: 10,
        ),
        isTrue,
      );
      expect(
        ChatCallTimeline.involvesThread(
          call: call,
          peerUserId: 20,
          currentUserId: 99,
        ),
        isFalse,
      );
    });
  });
}
