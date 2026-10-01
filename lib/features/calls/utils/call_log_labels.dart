import '../data/models/call.dart';
import 'call_ring_timeout.dart';

/// Display labels for inline call history bubbles in chat.
class CallLogLabels {
  CallLogLabels._();

  static const _ringingStatuses = {
    'initiating',
    'initiated',
    'ringing',
  };

  static const _talkingStatuses = {
    'active',
    'connected',
    'accepted',
  };

  static bool isTerminalStatus(String status) {
    return const {
      'ended',
      'missed',
      'rejected',
      'declined',
      'busy',
      'cancelled',
    }.contains(status);
  }

  static bool isLiveStatus(String status) {
    return _ringingStatuses.contains(status) || _talkingStatuses.contains(status);
  }

  /// History rows can stay `ringing` forever if the missed-call job never ran.
  static String resolvedStatus(
    Call call, {
    DateTime? now,
    int? liveCallId,
  }) {
    final status = call.status.toLowerCase();
    if (!isLiveStatus(status)) return status;

    final clock = now ?? DateTime.now();
    if (_ringingStatuses.contains(status)) {
      if (clock.difference(call.startedAt) > CallRingTimeout.duration) {
        return 'missed';
      }
      return status;
    }

    if (liveCallId != null && liveCallId == call.id) return status;
    if (liveCallId != null && liveCallId != call.id) return 'ended';
    if (clock.difference(call.startedAt) > const Duration(hours: 4)) {
      return 'ended';
    }
    return status;
  }

  static Call withResolvedStatus(
    Call call, {
    DateTime? now,
    int? liveCallId,
  }) {
    final next = resolvedStatus(call, now: now, liveCallId: liveCallId);
    if (next == call.status.toLowerCase()) return call;
    return call.copyWith(
      status: next,
      endedAt: isTerminalStatus(next) ? (call.endedAt ?? now ?? DateTime.now()) : call.endedAt,
    );
  }

  static String title({
    required Call call,
    required int currentUserId,
    DateTime? now,
    int? liveCallId,
  }) {
    final isVideo = call.isVideoCall;
    final media = isVideo ? 'Video call' : 'Voice call';
    final outgoing = call.callerId == currentUserId;
    final status = resolvedStatus(call, now: now, liveCallId: liveCallId);

    switch (status) {
      case 'initiating':
      case 'initiated':
      case 'ringing':
        return 'Connecting…';
      case 'missed':
        return outgoing ? 'No answer' : 'Missed ${isVideo ? 'video' : 'voice'} call';
      case 'rejected':
      case 'declined':
        return outgoing ? 'Call declined' : 'Missed ${isVideo ? 'video' : 'voice'} call';
      case 'busy':
        return 'Line busy';
      case 'cancelled':
        return outgoing ? 'Cancelled' : 'Missed ${isVideo ? 'video' : 'voice'} call';
      case 'ended':
      case 'active':
      case 'connected':
      case 'accepted':
        // [duration] is talk time (ended_at − answered_at), not ring time.
        final seconds = call.duration?.inSeconds ?? 0;
        if (seconds > 0) {
          return '$media · ${call.formattedDuration}';
        }
        return _talkingStatuses.contains(status) ? 'On a call' : media;
      default:
        return media;
    }
  }

  /// Compact subtitle for the messenger Calls list.
  static String listSubtitle({
    required Call call,
    required int currentUserId,
    int count = 1,
    int missedCount = 0,
  }) {
    if (missedCount > 1 &&
        isMissedOrDeclined(call: call, currentUserId: currentUserId)) {
      return '$missedCount missed calls';
    }
    final status = title(call: call, currentUserId: currentUserId);
    if (count > 1) return '$status · $count calls';
    return status;
  }

  static bool isMissedOrDeclined({
    required Call call,
    required int currentUserId,
    DateTime? now,
    int? liveCallId,
  }) {
    final status = resolvedStatus(call, now: now, liveCallId: liveCallId);
    if (status == 'missed' || status == 'busy') return true;
    if ((status == 'rejected' || status == 'declined') &&
        call.receiverId == currentUserId) {
      return true;
    }
    return false;
  }
}
