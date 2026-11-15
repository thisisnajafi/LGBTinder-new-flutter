import '../../../shared/models/api_error.dart';

/// Idempotent call teardown coordinator.
///
/// Every hang-up path (local button, remote Agora offline, Pusher `call.ended`,
/// CallKit / notification end) must call [beginEnd] first. A second request for
/// the same [callId] is a no-op so navigation and API posts run once.
class CallEndOrchestrator {
  CallEndOrchestrator();

  /// Process-wide instance used by live call screens and system hang-up.
  static final CallEndOrchestrator instance = CallEndOrchestrator();

  final Map<String, _CallEndPhase> _phases = <String, _CallEndPhase>{};

  /// Returns `true` only for the first end request for [callId].
  ///
  /// Empty / invalid ids are treated as unique one-shots so UI can still leave.
  bool beginEnd(String callId) {
    final key = callId.trim();
    if (key.isEmpty || key == '0') {
      return true;
    }
    final phase = _phases[key];
    if (phase == _CallEndPhase.ending || phase == _CallEndPhase.ended) {
      return false;
    }
    _phases[key] = _CallEndPhase.ending;
    return true;
  }

  void markEnded(String callId) {
    final key = callId.trim();
    if (key.isEmpty || key == '0') return;
    _phases[key] = _CallEndPhase.ended;
  }

  bool isEndingOrEnded(String callId) {
    final key = callId.trim();
    if (key.isEmpty || key == '0') return false;
    final phase = _phases[key];
    return phase == _CallEndPhase.ending || phase == _CallEndPhase.ended;
  }

  /// Clears tracking so a new session with the same id can end again (tests).
  void reset([String? callId]) {
    if (callId == null) {
      _phases.clear();
      return;
    }
    _phases.remove(callId.trim());
  }

  /// Server already closed the call (remote hang-up / race). Treat as success.
  static bool isInactiveEndSuccess(Object error) {
    if (error is ApiError) {
      if (error.code == 404) return true;
      final code = (error.errorCode ?? '').toUpperCase();
      if (code == 'NOT_FOUND' || code == 'CALL_NOT_FOUND') return true;
      return _messageMeansInactive(error.message);
    }
    return _messageMeansInactive(error.toString());
  }

  static bool _messageMeansInactive(String raw) {
    final message = raw.toLowerCase();
    if (message.contains('not found') && message.contains('call')) {
      return true;
    }
    if (message.contains('not active')) return true;
    if (message.contains('call not found')) return true;
    return false;
  }

  /// Whether an incoming full-screen route should be pushed for [callId].
  static bool shouldPresentIncomingRoute({
    required String callId,
    required String? alreadyPresentedCallId,
    required bool openingInFlight,
    required bool stackAlreadyShowsCallUi,
  }) {
    if (callId.isEmpty) return false;
    if (openingInFlight) return false;
    if (stackAlreadyShowsCallUi) return false;
    if (alreadyPresentedCallId == callId) return false;
    return true;
  }
}

enum _CallEndPhase { ending, ended }
