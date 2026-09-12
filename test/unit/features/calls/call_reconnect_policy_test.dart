import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/data/models/call_reconnect_policy.dart';

void main() {
  group('CallReconnectPolicy', () {
    test('allows three rejoins then gives up', () {
      final policy = CallReconnectPolicy();

      expect(policy.beginRetry(), isTrue);
      expect(policy.attempts, 1);
      policy.markRetryFinished();

      expect(policy.beginRetry(), isTrue);
      policy.markRetryFinished();
      expect(policy.beginRetry(), isTrue);
      policy.markRetryFinished();

      expect(policy.canRetry, isFalse);
      expect(policy.beginRetry(), isFalse);
      expect(policy.shouldGiveUp, isTrue);
    });

    test('recovery resets the attempt counter', () {
      final policy = CallReconnectPolicy();
      expect(policy.beginRetry(), isTrue);
      policy.markRetryFinished();
      policy.markRecovered();

      expect(policy.attempts, 0);
      expect(policy.canRetry, isTrue);
      expect(policy.shouldGiveUp, isFalse);
    });

    test('does not start a second retry while one is in flight', () {
      final policy = CallReconnectPolicy();
      expect(policy.beginRetry(), isTrue);
      expect(policy.beginRetry(), isFalse);
      expect(policy.attempts, 1);
      expect(policy.shouldGiveUp, isFalse);
    });
  });
}
