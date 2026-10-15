import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/models/call_action_request.dart';
import 'package:lgbtindernew/features/calls/utils/call_ring_timeout.dart';
import 'package:lgbtindernew/features/calls/utils/outgoing_call_end.dart';

void main() {
  group('OutgoingCallEnd.shouldNotifyServer', () {
    test('notifies while a ringing call is still open', () {
      expect(
        OutgoingCallEnd.shouldNotifyServer(
          callId: 67,
          endAlreadyPosted: false,
          remoteAlreadyTerminal: false,
          keepingEngine: false,
        ),
        isTrue,
      );
    });

    test('skips when end was already posted, remote finished, or minimized', () {
      expect(
        OutgoingCallEnd.shouldNotifyServer(
          callId: 67,
          endAlreadyPosted: true,
          remoteAlreadyTerminal: false,
          keepingEngine: false,
        ),
        isFalse,
      );
      expect(
        OutgoingCallEnd.shouldNotifyServer(
          callId: 67,
          endAlreadyPosted: false,
          remoteAlreadyTerminal: true,
          keepingEngine: false,
        ),
        isFalse,
      );
      expect(
        OutgoingCallEnd.shouldNotifyServer(
          callId: 67,
          endAlreadyPosted: false,
          remoteAlreadyTerminal: false,
          keepingEngine: true,
        ),
        isFalse,
      );
      expect(
        OutgoingCallEnd.shouldNotifyServer(
          callId: 0,
          endAlreadyPosted: false,
          remoteAlreadyTerminal: false,
          keepingEngine: false,
        ),
        isFalse,
      );
    });

    test('permission dialog pause does not cancel the outgoing call', () {
      expect(
        OutgoingCallEnd.shouldNotifyServer(
          callId: 64,
          endAlreadyPosted: false,
          remoteAlreadyTerminal: false,
          keepingEngine: false,
          permissionDialogVisible: true,
        ),
        isFalse,
      );
    });
  });

  group('OutgoingCallEnd.reasonForLeave', () {
    test('ring timeout sends caller-timeout', () {
      expect(
        OutgoingCallEnd.reasonForLeave(ringTimedOut: true),
        CallRingTimeout.callerTimeoutReason,
      );
    });

    test('leaving the screen another way is a normal hang-up', () {
      expect(OutgoingCallEnd.reasonForLeave(ringTimedOut: false), isNull);
    });
  });

  group('OutgoingCallEnd.shouldTreatAsCallerTimeout', () {
    test('unanswered or unknown status is a caller timeout', () {
      expect(
        OutgoingCallEnd.shouldTreatAsCallerTimeout(
          connected: false,
          alreadyLeft: false,
          serverStatus: 'ringing',
        ),
        isTrue,
      );
      expect(
        OutgoingCallEnd.shouldTreatAsCallerTimeout(
          connected: false,
          alreadyLeft: false,
          serverStatus: null,
        ),
        isTrue,
      );
    });

    test('connected, left, or already terminal calls are not a timeout end', () {
      expect(
        OutgoingCallEnd.shouldTreatAsCallerTimeout(
          connected: true,
          alreadyLeft: false,
          serverStatus: 'ringing',
        ),
        isFalse,
      );
      expect(
        OutgoingCallEnd.shouldTreatAsCallerTimeout(
          connected: false,
          alreadyLeft: true,
          serverStatus: 'ringing',
        ),
        isFalse,
      );
      expect(
        OutgoingCallEnd.shouldTreatAsCallerTimeout(
          connected: false,
          alreadyLeft: false,
          serverStatus: 'active',
        ),
        isFalse,
      );
      expect(
        OutgoingCallEnd.shouldTreatAsCallerTimeout(
          connected: false,
          alreadyLeft: false,
          serverStatus: 'rejected',
        ),
        isFalse,
      );
    });
  });

  group('CallActionRequest.end', () {
    test('includes caller-timeout reason for the end endpoint', () {
      final json = CallActionRequest.end(
        '67',
        reason: CallRingTimeout.callerTimeoutReason,
      ).toJson();
      expect(json['call_id'], '67');
      expect(json['action'], 'end');
      expect(json['reason'], 'caller-timeout');
    });

    test('omits reason on a normal hang-up', () {
      expect(CallActionRequest.end('67').toJson().containsKey('reason'), isFalse);
    });
  });
}
