import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/auth/data/models/login_response.dart';
import 'package:lgbtindernew/features/calls/utils/messenger_call_groups.dart';

Call _call({
  required int id,
  required int callerId,
  required int receiverId,
  required String status,
  String callType = 'audio',
  DateTime? startedAt,
  UserData? caller,
  UserData? receiver,
}) {
  return Call(
    id: id,
    callId: id.toString(),
    callerId: callerId,
    receiverId: receiverId,
    caller: caller,
    receiver: receiver,
    callType: callType,
    status: status,
    startedAt: startedAt ?? DateTime(2026, 8, 21, 16, id),
  );
}

UserData _user(int id, String first) => UserData(
      id: id,
      firstName: first,
      lastName: 'N',
      email: '$id@test.com',
    );

void main() {
  group('groupMessengerCalls', () {
    test('groups consecutive calls with the same peer, not all history', () {
      const me = 1;
      final alireza = _user(20, 'Alireza');
      final sara = _user(30, 'Sara');
      final calls = [
        _call(
          id: 7,
          callerId: me,
          receiverId: 20,
          status: 'ended',
          receiver: alireza,
          startedAt: DateTime(2026, 8, 21, 16, 7),
        ),
        _call(
          id: 6,
          callerId: me,
          receiverId: 20,
          status: 'ended',
          receiver: alireza,
          startedAt: DateTime(2026, 8, 21, 16, 6),
        ),
        _call(
          id: 5,
          callerId: me,
          receiverId: 20,
          status: 'ended',
          receiver: alireza,
          startedAt: DateTime(2026, 8, 21, 16, 5),
        ),
        _call(
          id: 4,
          callerId: me,
          receiverId: 30,
          status: 'ended',
          receiver: sara,
          startedAt: DateTime(2026, 8, 21, 16, 4),
        ),
        _call(
          id: 3,
          callerId: me,
          receiverId: 30,
          status: 'ended',
          receiver: sara,
          startedAt: DateTime(2026, 8, 21, 16, 3),
        ),
        _call(
          id: 2,
          callerId: me,
          receiverId: 20,
          status: 'ended',
          receiver: alireza,
          startedAt: DateTime(2026, 8, 21, 16, 2),
        ),
        _call(
          id: 1,
          callerId: me,
          receiverId: 30,
          status: 'ended',
          receiver: sara,
          startedAt: DateTime(2026, 8, 21, 16, 1),
        ),
      ];

      final groups = groupMessengerCalls(calls: calls, currentUserId: me);

      expect(groups, hasLength(4));
      expect(groups[0].peerName, 'Alireza N');
      expect(groups[0].count, 3);
      expect(groups[0].latest.id, 7);
      expect(groups[1].peerName, 'Sara N');
      expect(groups[1].count, 2);
      expect(groups[1].latest.id, 4);
      expect(groups[2].peerId, 20);
      expect(groups[2].count, 1);
      expect(groups[2].latest.id, 2);
      expect(groups[3].peerId, 30);
      expect(groups[3].count, 1);
    });

    test('missed filter only keeps missed or declined incoming calls', () {
      const me = 1;
      final calls = [
        _call(id: 1, callerId: 20, receiverId: me, status: 'missed'),
        _call(id: 2, callerId: me, receiverId: 20, status: 'ended'),
        _call(id: 3, callerId: 20, receiverId: me, status: 'rejected'),
      ];

      final groups = groupMessengerCalls(
        calls: calls,
        currentUserId: me,
        filter: MessengerCallFilter.missed,
      );

      expect(groups, hasLength(1));
      expect(groups.first.count, 2);
      expect(groups.first.missedCount, 2);
    });
  });
}
