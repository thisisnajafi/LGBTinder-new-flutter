import '../data/models/call.dart';

/// Display labels for inline call history bubbles in chat.
class CallLogLabels {
  CallLogLabels._();

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
    return const {
      'initiating',
      'initiated',
      'ringing',
      'active',
      'connected',
    }.contains(status);
  }

  static String title({
    required Call call,
    required int currentUserId,
  }) {
    final isVideo = call.isVideoCall;
    final media = isVideo ? 'Video call' : 'Voice call';
    final outgoing = call.callerId == currentUserId;

    switch (call.status) {
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
        // [duration] is talk time (ended_at − answered_at), not ring time.
        final seconds = call.duration?.inSeconds ?? 0;
        if (seconds > 0) {
          return '$media · ${call.formattedDuration}';
        }
        return call.status == 'active' || call.status == 'connected'
            ? 'On a call'
            : media;
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
  }) {
    if (call.status == 'missed' || call.status == 'busy') return true;
    if ((call.status == 'rejected' || call.status == 'declined') &&
        call.receiverId == currentUserId) {
      return true;
    }
    return false;
  }
}
