import '../../auth/data/models/login_response.dart';
import '../data/models/call.dart';
import '../data/models/incoming_call_data.dart';

/// Build a [Call] row from a Pusher / push payload for the Calls tab.
Call? messengerCallFromPayload(
  Map<String, dynamic> payload, {
  required int currentUserId,
}) {
  try {
    if (payload['id'] != null || payload['call_id'] != null) {
      final parsed = Call.fromJson(payload);
      if (parsed.id > 0 && parsed.callerId > 0) {
        final status = parsed.status.toLowerCase();
        final resolvedStatus =
            status.isEmpty || status == 'unknown' ? 'ringing' : parsed.status;
        if (parsed.receiverId > 0) {
          return parsed.copyWith(status: resolvedStatus);
        }
        if (currentUserId > 0 && parsed.callerId != currentUserId) {
          return parsed.copyWith(
            receiverId: currentUserId,
            status: resolvedStatus,
          );
        }
      }
    }
  } catch (_) {}

  final data = IncomingCallData.fromPayload(payload);
  if (data == null) return null;
  final id = int.tryParse(data.callId) ?? 0;
  if (id <= 0 || data.callerId <= 0 || currentUserId <= 0) return null;
  final parts = data.callerName.trim().split(RegExp(r'\s+'));
  final first = parts.isNotEmpty ? parts.first : data.callerName;
  final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
  return Call(
    id: id,
    callId: data.callId,
    callerId: data.callerId,
    receiverId: currentUserId,
    caller: UserData(
      id: data.callerId,
      firstName: first,
      lastName: last,
      email: '',
      avatarUrl: data.callerAvatar,
    ),
    callType: data.isVideo ? 'video' : 'audio',
    status: 'ringing',
    startedAt: DateTime.now(),
  );
}

Duration? durationFromCallPayload(Map<String, dynamic> payload) {
  final raw = payload['duration'] ?? payload['duration_seconds'];
  if (raw == null) return null;
  final seconds = raw is int ? raw : int.tryParse(raw.toString());
  if (seconds == null || seconds <= 0) return null;
  return Duration(seconds: seconds);
}
