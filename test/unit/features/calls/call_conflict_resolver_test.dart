import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/models/call.dart';
import 'package:lgbtindernew/features/calls/utils/call_conflict_resolver.dart';

Call _call({
  required String status,
  int callerId = 10,
  int receiverId = 20,
  DateTime? startedAt,
}) {
  return Call(
    id: 62,
    callId: '62',
    callerId: callerId,
    receiverId: receiverId,
    callType: 'audio',
    status: status,
    startedAt: startedAt ?? DateTime(2026, 10, 15, 12),
  );
}

void main() {
  final now = DateTime(2026, 10, 15, 12);

  group('CallConflictResolver', () {
    test('fresh ringing with the peer is cleared instead of failing', () {
      expect(
        CallConflictResolver.decide(
          existing: _call(status: 'ringing', startedAt: now.subtract(const Duration(seconds: 10))),
          peerId: 20,
          now: now,
        ),
        CallConflictAction.clearAndRetry,
      );
    });

    test('stale ringing past 45s is cleared', () {
      expect(
        CallConflictResolver.decide(
          existing: _call(status: 'initiating', startedAt: now.subtract(const Duration(days: 41))),
          peerId: 10,
          now: now,
        ),
        CallConflictAction.clearAndRetry,
      );
    });

    test('fresh active call with the peer is rejoined', () {
      expect(
        CallConflictResolver.decide(
          existing: _call(status: 'active', startedAt: now.subtract(const Duration(minutes: 2))),
          peerId: 20,
          now: now,
        ),
        CallConflictAction.rejoin,
      );
    });

    test('active call older than 4 hours is cleared', () {
      expect(
        CallConflictResolver.decide(
          existing: _call(status: 'active', startedAt: now.subtract(const Duration(hours: 5))),
          peerId: 20,
          now: now,
        ),
        CallConflictAction.clearAndRetry,
      );
    });

    test('a live call with someone else is busy', () {
      expect(
        CallConflictResolver.decide(
          existing: _call(status: 'active', callerId: 10, receiverId: 99),
          peerId: 20,
          now: now,
        ),
        CallConflictAction.busyElsewhere,
      );
    });

    test('ended, busy, and unknown rows are not rejoined', () {
      for (final status in ['ended', 'busy', 'missed', 'unknown']) {
        expect(
          CallConflictResolver.decide(
            existing: _call(status: status),
            peerId: 20,
            now: now,
          ),
          CallConflictAction.giveUp,
          reason: status,
        );
      }
    });

    test('missing active payload gives up', () {
      expect(
        CallConflictResolver.decide(existing: null, peerId: 20, now: now),
        CallConflictAction.giveUp,
      );
    });
  });
}
