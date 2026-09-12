import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/core/constants/animation_constants.dart';
import 'package:lgbtindernew/features/calls/data/models/call_duration_formatter.dart';
import 'package:lgbtindernew/features/calls/data/models/call_end_summary.dart';
import 'package:lgbtindernew/features/calls/data/models/call_reconnect_policy.dart';

void main() {
  group('CallDurationFormatter.formatLong', () {
    test('uses seconds only under a minute', () {
      expect(CallDurationFormatter.formatLong(Duration.zero), '0 seconds');
      expect(
        CallDurationFormatter.formatLong(const Duration(seconds: 1)),
        '1 second',
      );
      expect(
        CallDurationFormatter.formatLong(const Duration(seconds: 45)),
        '45 seconds',
      );
    });

    test('includes minutes and seconds', () {
      expect(
        CallDurationFormatter.formatLong(const Duration(minutes: 2, seconds: 4)),
        '2 minutes 4 seconds',
      );
      expect(
        CallDurationFormatter.formatLong(const Duration(minutes: 1)),
        '1 minute 0 seconds',
      );
    });
  });

  group('CallEndSummary', () {
    test('connected calls show duration', () {
      const summary = CallEndSummary(
        reason: CallEndReason.ended,
        talkTime: Duration(seconds: 12),
        isVideo: true,
        wasConnected: true,
      );
      expect(summary.showDuration, isTrue);
      expect(summary.durationLabel, '12 seconds');
      expect(summary.title, 'Call ended');
    });

    test('missed calls hide duration', () {
      const summary = CallEndSummary(
        reason: CallEndReason.missed,
        talkTime: Duration.zero,
        isVideo: false,
        wasConnected: false,
      );
      expect(summary.showDuration, isFalse);
      expect(summary.durationLabel, isNull);
      expect(summary.title, 'No answer');
    });

    test('resolve maps status and connection lost', () {
      expect(
        CallEndSummary.resolve(wasConnected: false, status: 'busy'),
        CallEndReason.busy,
      );
      expect(
        CallEndSummary.resolve(wasConnected: false, status: 'rejected'),
        CallEndReason.declined,
      );
      expect(
        CallEndSummary.resolve(
          wasConnected: true,
          connectionError: CallReconnectPolicy.lostMessage,
        ),
        CallEndReason.connectionLost,
      );
      expect(
        CallEndSummary.resolve(wasConnected: true),
        CallEndReason.ended,
      );
      expect(
        CallEndSummary.resolve(wasConnected: false),
        CallEndReason.missed,
      );
    });

    test('Reduce Motion skips fade and shortens hold', () {
      expect(
        CallEndSummary.fadeDuration(reduceMotion: true),
        Duration.zero,
      );
      expect(
        CallEndSummary.holdDuration(reduceMotion: true),
        AppAnimations.callEndHoldReduced,
      );
      expect(
        CallEndSummary.holdDuration(reduceMotion: false),
        AppAnimations.callEndHold,
      );
    });
  });
}
