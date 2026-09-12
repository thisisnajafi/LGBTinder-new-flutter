import '../../../../core/constants/animation_constants.dart';
import 'call_duration_formatter.dart';
import 'call_reconnect_policy.dart';

enum CallEndReason {
  declined,
  missed,
  ended,
  busy,
  connectionLost,
}

/// Snapshot shown on the hang-up summary card.
class CallEndSummary {
  final CallEndReason reason;
  final Duration talkTime;
  final bool isVideo;
  final bool wasConnected;

  const CallEndSummary({
    required this.reason,
    required this.talkTime,
    required this.isVideo,
    required this.wasConnected,
  });

  static CallEndReason resolve({
    required bool wasConnected,
    String? status,
    String? connectionError,
  }) {
    if (connectionError == CallReconnectPolicy.lostMessage) {
      return CallEndReason.connectionLost;
    }
    switch (status?.toLowerCase()) {
      case 'busy':
        return CallEndReason.busy;
      case 'rejected':
      case 'declined':
        return CallEndReason.declined;
      case 'missed':
      case 'cancelled':
        return CallEndReason.missed;
      case 'ended':
      case 'active':
      case 'connected':
        return CallEndReason.ended;
    }
    return wasConnected ? CallEndReason.ended : CallEndReason.missed;
  }

  String get title {
    switch (reason) {
      case CallEndReason.declined:
        return 'Call declined';
      case CallEndReason.missed:
        return 'No answer';
      case CallEndReason.ended:
        return 'Call ended';
      case CallEndReason.busy:
        return 'Line busy';
      case CallEndReason.connectionLost:
        return CallReconnectPolicy.lostMessage;
    }
  }

  bool get showDuration => wasConnected;

  String? get durationLabel =>
      showDuration ? CallDurationFormatter.formatLong(talkTime) : null;

  static Duration fadeDuration({required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : AppAnimations.callEndFade;

  static Duration holdDuration({required bool reduceMotion}) =>
      reduceMotion
          ? AppAnimations.callEndHoldReduced
          : AppAnimations.callEndHold;
}
