import '../../../shared/services/agora_rtc_types.dart';

/// Rising-edge + cooldown gate so quality ticks do not spam toasts (CALL-FEAT-005).
class CallQualityToastGate {
  CallQualityToastGate({
    this.debounce = const Duration(seconds: 5),
  });

  final Duration debounce;

  DateTime? _lastShownAt;
  bool _inToastBand = false;

  bool take({
    required String quality,
    required DateTime now,
  }) {
    if (!AgoraNetworkQuality.shouldToast(quality)) {
      _inToastBand = false;
      return false;
    }
    if (_inToastBand) return false;
    if (_lastShownAt != null && now.difference(_lastShownAt!) < debounce) {
      return false;
    }
    _inToastBand = true;
    _lastShownAt = now;
    return true;
  }
}
