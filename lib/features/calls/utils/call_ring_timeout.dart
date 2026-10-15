/// Single ringing timeout (CALL-FEAT-003).
///
/// Backend [Call::RING_TIMEOUT_SECONDS], [CheckMissedCall], and
/// `calls:update-missed` use the same 45 seconds. When the caller timer
/// fires, the app POSTs `/calls/end` with [callerTimeoutReason] so the
/// server marks the row missed. The timer must not `POST reject`.
class CallRingTimeout {
  CallRingTimeout._();

  static const int seconds = 45;
  static const Duration duration = Duration(seconds: seconds);

  /// Extra ring time after the callee taps Accept (permission prompts).
  /// Matches [Call::ACCEPTING_GRACE_SECONDS].
  static const int acceptingGraceSeconds = 60;
  static const Duration acceptingGrace = Duration(seconds: acceptingGraceSeconds);

  /// Matches [Call::END_REASON_CALLER_TIMEOUT].
  static const String callerTimeoutReason = 'caller-timeout';

  static int get milliseconds => duration.inMilliseconds;
}
