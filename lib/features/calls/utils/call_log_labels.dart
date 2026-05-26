import '../data/models/call.dart';

/// Display labels for inline call history bubbles in chat.
class CallLogLabels {
  CallLogLabels._();

  static bool isTerminalStatus(String status) {
    return const {
      'ended',
      'missed',
      'rejected',
      'busy',
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
      case 'missed':
        return outgoing ? 'No answer' : 'Missed ${isVideo ? 'video' : 'voice'} call';
      case 'rejected':
        return outgoing ? 'Call declined' : 'Missed ${isVideo ? 'video' : 'voice'} call';
      case 'busy':
        return 'Line busy';
      case 'ended':
      case 'active':
        final seconds = call.duration?.inSeconds ?? 0;
        if (seconds > 0) {
          return '$media · ${call.formattedDuration}';
        }
        return media;
      default:
        return media;
    }
  }

  static bool isMissedOrDeclined({
    required Call call,
    required int currentUserId,
  }) {
    if (call.status == 'missed' || call.status == 'busy') return true;
    if (call.status == 'rejected' && call.receiverId == currentUserId) {
      return true;
    }
    return false;
  }
}
