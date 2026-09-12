import '../../calls/data/models/call.dart';
import '../../calls/utils/call_log_labels.dart';
import 'chat_optimistic.dart';
import 'chat_timeline_merger.dart';

/// Upsert call-log rows in the chat timeline (CALL-FEAT-003).
class ChatCallTimeline {
  ChatCallTimeline._();

  static int indexOfCallId(List<Map<String, dynamic>> rows, int callId) {
    if (callId <= 0) return -1;
    final needle = callId.toString();
    for (var i = 0; i < rows.length; i++) {
      if (rows[i]['kind'] == 'call' &&
          rows[i]['call_id']?.toString() == needle) {
        return i;
      }
    }
    return -1;
  }

  /// Merge [callRow] by `call_id`. Later terminal status wins over a live row.
  static List<Map<String, dynamic>> upsert(
    List<Map<String, dynamic>> rows,
    Map<String, dynamic> callRow,
  ) {
    final callId = ChatOptimistic.parseMessageId(callRow['call_id']);
    if (callId <= 0) return rows;

    final incoming = callRow['call'];
    if (incoming is Call &&
        !CallLogLabels.isTerminalStatus(incoming.status.toLowerCase())) {
      final at = indexOfCallId(rows, callId);
      if (at >= 0) {
        final existing = rows[at]['call'];
        if (existing is Call &&
            CallLogLabels.isTerminalStatus(existing.status.toLowerCase())) {
          return rows;
        }
      }
    }

    final messages = rows.where((e) => e['kind'] != 'call').toList();
    final calls = rows.where((e) => e['kind'] == 'call').toList();
    return ChatTimelineMerger.merge(
      messages: messages,
      calls: [...calls, callRow],
    );
  }

  /// Build a terminal [Call] from `call.ended` / rejected / busy payload.
  static Call? fromSignalingPayload(Map<String, dynamic> payload) {
    final id = ChatOptimistic.parseMessageId(
      payload['call_id'] ?? payload['id'],
    );
    if (id <= 0) return null;

    final status = payload['status']?.toString().toLowerCase() ?? '';
    if (!CallLogLabels.isTerminalStatus(status)) return null;

    final callerId = ChatOptimistic.parseMessageId(payload['caller_id']);
    final receiverId = ChatOptimistic.parseMessageId(payload['receiver_id']);
    if (callerId <= 0 || receiverId <= 0) return null;

    return Call.fromJson({
      'id': id,
      'call_id': id.toString(),
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': payload['call_type'] ?? 'audio',
      'status': status,
      'ended_at': payload['ended_at'],
      'duration': payload['duration'],
      'end_reason': payload['reason'],
    });
  }

  static bool involvesThread({
    required Call call,
    required int peerUserId,
    int? currentUserId,
  }) {
    if (peerUserId <= 0) return false;
    if (currentUserId != null && currentUserId > 0) {
      return (call.callerId == currentUserId && call.receiverId == peerUserId) ||
          (call.callerId == peerUserId && call.receiverId == currentUserId);
    }
    return call.callerId == peerUserId || call.receiverId == peerUserId;
  }
}
