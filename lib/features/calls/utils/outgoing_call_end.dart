import 'call_log_labels.dart';
import 'call_ring_timeout.dart';

/// When the outgoing screen must POST `/calls/end`.
///
/// Ring timeout uses [CallRingTimeout.callerTimeoutReason] so the server
/// stores missed. Any other leave (back, dispose, permission exit) still
/// posts end so a ringing row is not left behind. Minimize keeps the engine
/// and does not end the call.
class OutgoingCallEnd {
  OutgoingCallEnd._();

  static bool shouldNotifyServer({
    required int callId,
    required bool endAlreadyPosted,
    required bool remoteAlreadyTerminal,
    required bool keepingEngine,
  }) {
    if (keepingEngine) return false;
    if (callId <= 0) return false;
    if (endAlreadyPosted || remoteAlreadyTerminal) return false;
    return true;
  }

  /// Null means a normal hang-up (server: cancelled if the caller never connected).
  static String? reasonForLeave({required bool ringTimedOut}) {
    if (!ringTimedOut) return null;
    return CallRingTimeout.callerTimeoutReason;
  }

  /// Ring timer: still unanswered, so tell the server it was a caller timeout.
  ///
  /// [serverStatus] null means the status read failed; the caller still notifies.
  static bool shouldTreatAsCallerTimeout({
    required bool connected,
    required bool alreadyLeft,
    required String? serverStatus,
  }) {
    if (connected || alreadyLeft) return false;
    if (serverStatus == null || serverStatus.trim().isEmpty) return true;
    final status = serverStatus.toLowerCase();
    if (status == 'active' || status == 'connected' || status == 'accepted') {
      return false;
    }
    if (CallLogLabels.isTerminalStatus(status)) return false;
    return true;
  }
}
