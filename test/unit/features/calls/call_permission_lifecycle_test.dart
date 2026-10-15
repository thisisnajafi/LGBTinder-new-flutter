import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/calls/utils/call_permission_lifecycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(CallPermissionLifecycle.debugReset);

  group('CallPermissionLifecycle.shouldPromoteIncomingToCallKit', () {
    test('resumed never promotes', () {
      expect(
        CallPermissionLifecycle.shouldPromoteIncomingToCallKit(
          state: AppLifecycleState.resumed,
          permissionRequestInFlight: false,
        ),
        isFalse,
      );
    });

    test('home and lock screen still promote', () {
      expect(
        CallPermissionLifecycle.shouldPromoteIncomingToCallKit(
          state: AppLifecycleState.paused,
          permissionRequestInFlight: false,
        ),
        isTrue,
      );
      expect(
        CallPermissionLifecycle.shouldPromoteIncomingToCallKit(
          state: AppLifecycleState.hidden,
          permissionRequestInFlight: false,
        ),
        isTrue,
      );
    });

    test('permission dialog pause does not promote to CallKit', () {
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
      ]) {
        expect(
          CallPermissionLifecycle.shouldPromoteIncomingToCallKit(
            state: state,
            permissionRequestInFlight: true,
          ),
          isFalse,
          reason: state.name,
        );
      }
    });
  });

  group('CallPermissionLifecycle terminal actions', () {
    test('decline and outgoing cancel are blocked only during the prompt', () {
      expect(
        CallPermissionLifecycle.shouldPostDecline(
          permissionRequestInFlight: true,
        ),
        isFalse,
      );
      expect(
        CallPermissionLifecycle.shouldCancelOutgoing(
          permissionRequestInFlight: true,
        ),
        isFalse,
      );
      expect(
        CallPermissionLifecycle.shouldPostDecline(
          permissionRequestInFlight: false,
        ),
        isTrue,
      );
      expect(
        CallPermissionLifecycle.shouldCancelOutgoing(
          permissionRequestInFlight: false,
        ),
        isTrue,
      );
    });

    test('request depth stays raised until every prompt finishes', () {
      CallPermissionLifecycle.beginRequest();
      CallPermissionLifecycle.beginRequest();
      expect(CallPermissionLifecycle.requestInFlight, isTrue);
      CallPermissionLifecycle.endRequest();
      expect(CallPermissionLifecycle.requestInFlight, isTrue);
      expect(CallPermissionLifecycle.blocksCallTerminalActions, isTrue);
      CallPermissionLifecycle.endRequest();
      expect(CallPermissionLifecycle.requestInFlight, isFalse);
      expect(CallPermissionLifecycle.blocksCallTerminalActions, isTrue);
    });
  });
}
