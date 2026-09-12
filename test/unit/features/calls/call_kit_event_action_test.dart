import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/services/call_kit_event_action.dart';

void main() {
  group('classifyCallKitEvent', () {
    test('accept stays accept', () {
      expect(
        classifyCallKitEvent(Event.actionCallAccept),
        CallKitEventAction.accept,
      );
    });

    test('decline posts reject', () {
      expect(
        classifyCallKitEvent(Event.actionCallDecline),
        CallKitEventAction.decline,
      );
    });

    test('timeout does not reject', () {
      expect(
        classifyCallKitEvent(Event.actionCallTimeout),
        CallKitEventAction.timeout,
      );
      expect(
        classifyCallKitEvent(Event.actionCallTimeout),
        isNot(CallKitEventAction.decline),
      );
    });

    test('callback returns to the live call', () {
      expect(
        classifyCallKitEvent(Event.actionCallCallback),
        CallKitEventAction.callback,
      );
    });

    test('ended does not reject — cold-start accept dismisses native UI', () {
      expect(
        classifyCallKitEvent(Event.actionCallEnded),
        CallKitEventAction.dismissOnly,
      );
    });
  });
}
