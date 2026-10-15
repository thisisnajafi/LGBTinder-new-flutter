import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/utils/call_busy_confirmation.dart';
import 'package:lgbtindernew/features/calls/utils/call_rejoin_policy.dart';
import 'package:lgbtindernew/features/calls/utils/minimized_call_remote_end.dart';
import 'package:lgbtindernew/shared/services/agora_rtc_types.dart';

void main() {
  group('MinimizedCallRemoteEnd.pusherMatches', () {
    test('matches the minimized session call id', () {
      expect(
        MinimizedCallRemoteEnd.pusherMatches(
          sessionCallId: 65,
          eventCallId: '65',
        ),
        isTrue,
      );
    });

    test('ignores a different call and an empty id', () {
      expect(
        MinimizedCallRemoteEnd.pusherMatches(
          sessionCallId: 65,
          eventCallId: '66',
        ),
        isFalse,
      );
      expect(
        MinimizedCallRemoteEnd.pusherMatches(
          sessionCallId: 65,
          eventCallId: '',
        ),
        isFalse,
      );
      expect(
        MinimizedCallRemoteEnd.pusherMatches(
          sessionCallId: null,
          eventCallId: '65',
        ),
        isFalse,
      );
    });
  });

  group('MinimizedCallRemoteEnd agora leave', () {
    test('quit and other end immediately', () {
      expect(
        MinimizedCallRemoteEnd.offlineEndsImmediately(
          CallRemoteLeaveReason.quit,
        ),
        isTrue,
      );
      expect(
        MinimizedCallRemoteEnd.offlineEndsImmediately(
          CallRemoteLeaveReason.other,
        ),
        isTrue,
      );
      expect(
        MinimizedCallRemoteEnd.offlineEndsImmediately(
          CallRemoteLeaveReason.dropped,
        ),
        isFalse,
      );
    });

    test('only a network drop waits out the grace period', () {
      expect(
        MinimizedCallRemoteEnd.offlineEndsAfterGrace(
          CallRemoteLeaveReason.dropped,
        ),
        isTrue,
      );
      expect(
        MinimizedCallRemoteEnd.offlineEndsAfterGrace(
          CallRemoteLeaveReason.quit,
        ),
        isFalse,
      );
    });
  });

  group('CallBusyConfirmation.serverConfirmsBusy', () {
    test('no server call, or this same invite, is not busy', () {
      expect(
        CallBusyConfirmation.serverConfirmsBusy(
          incomingCallId: '66',
          serverCallId: null,
          serverStatus: null,
        ),
        isFalse,
      );
      expect(
        CallBusyConfirmation.serverConfirmsBusy(
          incomingCallId: '66',
          serverCallId: 66,
          serverStatus: 'ringing',
        ),
        isFalse,
      );
    });

    test('a different live call is busy', () {
      expect(
        CallBusyConfirmation.serverConfirmsBusy(
          incomingCallId: '66',
          serverCallId: 65,
          serverStatus: 'active',
        ),
        isTrue,
      );
    });

    test('a terminal server row is not busy', () {
      for (final status in ['ended', 'busy', 'missed', 'rejected']) {
        expect(
          CallBusyConfirmation.serverConfirmsBusy(
            incomingCallId: '66',
            serverCallId: 65,
            serverStatus: status,
          ),
          isFalse,
          reason: status,
        );
      }
    });
  });

  group('CallRejoinPolicy.isActiveStatus', () {
    test('only active or connected may rejoin', () {
      expect(CallRejoinPolicy.isActiveStatus('active'), isTrue);
      expect(CallRejoinPolicy.isActiveStatus('connected'), isTrue);
      expect(CallRejoinPolicy.isActiveStatus('ACTIVE'), isTrue);
    });

    test('busy, ended, ringing, and unknown must not rejoin', () {
      for (final status in ['busy', 'ended', 'ringing', 'unknown', null]) {
        expect(CallRejoinPolicy.isActiveStatus(status), isFalse, reason: '$status');
      }
    });
  });
}
