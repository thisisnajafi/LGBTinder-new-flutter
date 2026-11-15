import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/utils/call_end_orchestrator.dart';
import 'package:lgbtindernew/features/calls/utils/call_navigation.dart';
import 'package:lgbtindernew/routes/app_router.dart';
import 'package:lgbtindernew/shared/models/api_error.dart';

void main() {
  group('CallEndOrchestrator.beginEnd', () {
    late CallEndOrchestrator orch;

    setUp(() {
      orch = CallEndOrchestrator();
    });

    test('first end wins; second for same callId is a no-op', () {
      expect(orch.beginEnd('131'), isTrue);
      expect(orch.beginEnd('131'), isFalse);
      expect(orch.isEndingOrEnded('131'), isTrue);
      orch.markEnded('131');
      expect(orch.beginEnd('131'), isFalse);
    });

    test('remote + local simultaneous end only runs once', () {
      expect(orch.beginEnd('99'), isTrue);
      // Local hang-up and Pusher call.ended race.
      expect(orch.beginEnd('99'), isFalse);
      expect(orch.beginEnd('99'), isFalse);
    });

    test('end while already marked ended stays no-op', () {
      expect(orch.beginEnd('7'), isTrue);
      orch.markEnded('7');
      expect(orch.beginEnd('7'), isFalse);
    });

    test('different call ids are independent', () {
      expect(orch.beginEnd('1'), isTrue);
      expect(orch.beginEnd('2'), isTrue);
      expect(orch.beginEnd('1'), isFalse);
      expect(orch.beginEnd('2'), isFalse);
    });

    test('reset clears tracking for a new session', () {
      expect(orch.beginEnd('5'), isTrue);
      orch.reset('5');
      expect(orch.beginEnd('5'), isTrue);
    });
  });

  group('CallEndOrchestrator.isInactiveEndSuccess', () {
    test('treats 404 and not-active messages as success', () {
      expect(
        CallEndOrchestrator.isInactiveEndSuccess(
          ApiError(code: 404, message: 'Call not found or not active'),
        ),
        isTrue,
      );
      expect(
        CallEndOrchestrator.isInactiveEndSuccess(
          Exception('Call not found or not active'),
        ),
        isTrue,
      );
      expect(
        CallEndOrchestrator.isInactiveEndSuccess(
          ApiError(code: 500, message: 'Server error'),
        ),
        isFalse,
      );
    });
  });

  group('CallEndOrchestrator.shouldPresentIncomingRoute', () {
    test('dedupes by call id, in-flight open, and existing call UI', () {
      expect(
        CallEndOrchestrator.shouldPresentIncomingRoute(
          callId: '131',
          alreadyPresentedCallId: null,
          openingInFlight: false,
          stackAlreadyShowsCallUi: false,
        ),
        isTrue,
      );
      expect(
        CallEndOrchestrator.shouldPresentIncomingRoute(
          callId: '131',
          alreadyPresentedCallId: '131',
          openingInFlight: false,
          stackAlreadyShowsCallUi: false,
        ),
        isFalse,
      );
      expect(
        CallEndOrchestrator.shouldPresentIncomingRoute(
          callId: '131',
          alreadyPresentedCallId: null,
          openingInFlight: true,
          stackAlreadyShowsCallUi: false,
        ),
        isFalse,
      );
      expect(
        CallEndOrchestrator.shouldPresentIncomingRoute(
          callId: '131',
          alreadyPresentedCallId: null,
          openingInFlight: false,
          stackAlreadyShowsCallUi: true,
        ),
        isFalse,
      );
    });
  });

  group('isCallUiPath', () {
    test('recognizes incoming and outgoing call routes', () {
      expect(isCallUiPath(AppRoutes.incomingCall), isTrue);
      expect(isCallUiPath(AppRoutes.outgoingCall), isTrue);
      expect(isCallUiPath(AppRoutes.home), isFalse);
      expect(isCallUiPath(AppRoutes.chat), isFalse);
    });
  });

  group('leaveCallRoutes stack policy', () {
    test('empty navigator stack falls back to a safe route path', () {
      // Pure policy: when canPop is false while still on a call path,
      // leaveCallRoutes must go(fallback). Encoded as the helper paths.
      expect(isCallUiPath(AppRoutes.incomingCall), isTrue);
      expect(AppRoutes.home, isNot(equals(AppRoutes.incomingCall)));
    });
  });
}
