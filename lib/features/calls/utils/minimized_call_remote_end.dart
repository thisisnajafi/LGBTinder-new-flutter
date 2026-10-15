import '../../../shared/services/agora_rtc_types.dart';

/// Whether a minimized call should drop local state after the remote side leaves.
class MinimizedCallRemoteEnd {
  MinimizedCallRemoteEnd._();

  /// Pusher `call.ended` / `call.rejected` / `call.busy` for this session.
  static bool pusherMatches({
    required int? sessionCallId,
    required String? eventCallId,
  }) {
    if (sessionCallId == null || sessionCallId <= 0) return false;
    final event = eventCallId?.trim() ?? '';
    if (event.isEmpty) return false;
    return sessionCallId.toString() == event;
  }

  /// Remote hang-up (`quit`) or an unclassified leave (`other`).
  static bool offlineEndsImmediately(CallRemoteLeaveReason reason) {
    return reason == CallRemoteLeaveReason.quit ||
        reason == CallRemoteLeaveReason.other;
  }

  /// Network drop. The session waits briefly in case the peer reconnects.
  static bool offlineEndsAfterGrace(CallRemoteLeaveReason reason) {
    return reason == CallRemoteLeaveReason.dropped;
  }
}
