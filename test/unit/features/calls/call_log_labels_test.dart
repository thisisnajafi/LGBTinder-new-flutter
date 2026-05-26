import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/utils/call_log_labels.dart';

Call _call({
  required int id,
  required int callerId,
  required int receiverId,
  required String status,
  String callType = 'audio',
  Duration? duration,
}) {
  return Call(
    id: id,
    callId: id.toString(),
    callerId: callerId,
    receiverId: receiverId,
    callType: callType,
    status: status,
    startedAt: DateTime(2026, 5, 24),
    duration: duration,
  );
}

void main() {
  group('CallLogLabels', () {
    test('isTerminalStatus recognizes completed call states', () {
      expect(CallLogLabels.isTerminalStatus('ended'), isTrue);
      expect(CallLogLabels.isTerminalStatus('missed'), isTrue);
      expect(CallLogLabels.isTerminalStatus('ringing'), isFalse);
    });

    test('title for ended call includes duration', () {
      final call = _call(
        id: 1,
        callerId: 10,
        receiverId: 20,
        status: 'ended',
        duration: const Duration(minutes: 2, seconds: 5),
      );

      expect(
        CallLogLabels.title(call: call, currentUserId: 10),
        'Voice call · 02:05',
      );
    });

    test('title for incoming missed video call', () {
      final call = _call(
        id: 2,
        callerId: 10,
        receiverId: 20,
        status: 'missed',
        callType: 'video',
      );

      expect(
        CallLogLabels.title(call: call, currentUserId: 20),
        'Missed video call',
      );
    });

    test('isMissedOrDeclined for callee on rejected call', () {
      final call = _call(
        id: 3,
        callerId: 10,
        receiverId: 20,
        status: 'rejected',
      );

      expect(
        CallLogLabels.isMissedOrDeclined(call: call, currentUserId: 20),
        isTrue,
      );
      expect(
        CallLogLabels.isMissedOrDeclined(call: call, currentUserId: 10),
        isFalse,
      );
    });
  });
}
