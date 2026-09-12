import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/utils/call_log_labels.dart';

void main() {
  test('call history json round-trip keeps timeline badge fields', () {
    final original = Call(
      id: 13,
      callId: '13',
      callerId: 1,
      receiverId: 2,
      callType: 'video',
      status: 'ended',
      startedAt: DateTime.parse('2026-08-21T20:00:00Z'),
      endedAt: DateTime.parse('2026-08-21T20:01:00Z'),
      duration: const Duration(seconds: 42),
    );

    final restored = Call.fromJson(original.toJson());

    expect(restored.id, 13);
    expect(restored.callType, 'video');
    expect(CallLogLabels.isTerminalStatus(restored.status), isTrue);
    expect(restored.duration?.inSeconds, 42);
    expect(restored.timelineTimestamp, original.timelineTimestamp);
  });
}
