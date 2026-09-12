/// Limits explicit Agora rejoin attempts after a drop during an active call.
class CallReconnectPolicy {
  static const int maxAttempts = 3;
  static const Duration watchdog = Duration(seconds: 12);
  static const Duration giveUpVisible = Duration(seconds: 2);
  static const String lostMessage = 'Connection lost';

  int _attempts = 0;
  bool _inFlight = false;

  int get attempts => _attempts;
  bool get inFlight => _inFlight;
  bool get canRetry => _attempts < maxAttempts;

  /// Starts one rejoin. Returns false when a retry is already running or
  /// [maxAttempts] has been used.
  bool beginRetry() {
    if (!canRetry || _inFlight) return false;
    _inFlight = true;
    _attempts++;
    return true;
  }

  void markRetryFinished() {
    _inFlight = false;
  }

  void markRecovered() {
    _attempts = 0;
    _inFlight = false;
  }

  bool get shouldGiveUp => !canRetry && !_inFlight;
}
