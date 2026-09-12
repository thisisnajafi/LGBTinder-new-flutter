import '../../../core/services/app_logger.dart';
import '../../../shared/services/chat_pusher_event_names.dart';
import '../data/models/incoming_call_data.dart';

/// Structured call-signaling logs (LOG-002). Tag floor is [LogLevel.info].
class CallSignalingLog {
  CallSignalingLog._();

  static const tag = 'CallSignaling';

  static const List<String> eventNames = [
    ChatPusherEventNames.callIncoming,
    ChatPusherEventNames.callAccepted,
    ChatPusherEventNames.callRejected,
    ChatPusherEventNames.callEnded,
    ChatPusherEventNames.callBusy,
  ];

  static bool isCallEvent(String eventName) => eventNames.contains(eventName);

  static String eventLine({
    required String eventName,
    String? callId,
    String? callerId,
  }) {
    final from = (callerId != null && callerId.isNotEmpty)
        ? callerId
        : 'unknown';
    final id = (callId != null && callId.isNotEmpty) ? callId : 'unknown';
    return 'Call event: $eventName from user $from call_id=$id';
  }

  static String eventLineFromPayload(
    String eventName,
    Map<String, dynamic> payload,
  ) {
    return eventLine(
      eventName: eventName,
      callId: IncomingCallData.callIdFromPayload(payload),
      callerId: callerIdFromPayload(payload),
    );
  }

  static String? callerIdFromPayload(Map<String, dynamic> payload) {
    final data = _unwrap(payload);
    final caller = data['caller'];
    final callerMap = caller is Map<String, dynamic>
        ? caller
        : (caller is Map ? Map<String, dynamic>.from(caller) : null);
    final raw = data['caller_id'] ??
        data['callerId'] ??
        data['user_id'] ??
        data['from_user_id'] ??
        callerMap?['id'];
    if (raw == null) return null;
    final value = raw.toString();
    return value.isEmpty ? null : value;
  }

  static String httpSuccess(String action, String callId) =>
      'HTTP $action ok call_id=$callId';

  static String httpError(String action, String callId) =>
      'HTTP $action failed call_id=$callId';

  static String dispatchLine(String eventName, Object? callId) =>
      'Dispatch $eventName call_id=$callId';

  static void logEvent(String eventName, Map<String, dynamic> payload) {
    AppLogger.info(eventLineFromPayload(eventName, payload), tag: tag);
  }

  static void logDispatch(String eventName, Object? callId) {
    AppLogger.info(dispatchLine(eventName, callId), tag: tag);
  }

  static void logHttpOk(String action, String callId) {
    AppLogger.info(httpSuccess(action, callId), tag: tag);
  }

  static void logHttpError(String action, String callId, Object error) {
    AppLogger.error(httpError(action, callId), tag: tag, error: error);
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    if (raw['call_id'] != null || raw['callId'] != null) return raw;
    final nested = raw['data'] ?? raw['custom'] ?? raw['payload'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return raw;
  }
}
