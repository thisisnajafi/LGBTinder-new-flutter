/// Single ringing timeout (CALL-FEAT-003).
///
/// Backend [Call::RING_TIMEOUT_SECONDS], [CheckMissedCall], and
/// `calls:update-missed` use the same 45 seconds. Flutter timers only dismiss
/// UI — they must not `POST reject`.
class CallRingTimeout {
  CallRingTimeout._();

  static const int seconds = 45;
  static const Duration duration = Duration(seconds: seconds);

  static int get milliseconds => duration.inMilliseconds;
}
