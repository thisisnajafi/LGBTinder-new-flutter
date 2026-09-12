import 'dart:convert';

/// Bridge for local-notification actions (non-Riverpod plugin callbacks).
class ActiveCallBridge {
  static void Function(String? actionId, String? payload)? handle;
  static String? pendingActionId;
  static String? pendingPayload;

  static void dispatch(String? actionId, String? payload) {
    final fn = handle;
    if (fn != null) {
      fn(actionId, payload);
      return;
    }
    pendingActionId = actionId;
    pendingPayload = payload;
  }

  static void consumePending() {
    final fn = handle;
    if (fn == null) return;
    if (pendingActionId == null && pendingPayload == null) return;
    fn(pendingActionId, pendingPayload);
    pendingActionId = null;
    pendingPayload = null;
  }
}

/// Payload + copy for the ongoing “Active call with {name}” notification.
class ActiveCallNotification {
  ActiveCallNotification._();

  static const String type = 'active_call';
  static const String actionReturn = 'active_call_return';
  static const String actionHangup = 'active_call_hangup';
  static const String androidChannelId = 'lgbtfinder_active_call';
  static const String androidChannelName = 'Active call';
  static const String iosCategory = 'ACTIVE_CALL';
  static const int notificationId = 71001;

  static String titleFor(String peerName) => 'Active call with $peerName';

  static String encode({
    required int callId,
    required String location,
    required String peerName,
  }) {
    return jsonEncode({
      'type': type,
      'call_id': callId.toString(),
      'location': location,
      'peer_name': peerName,
    });
  }

  static Map<String, dynamic>? decode(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      if (map['type']?.toString() != type) return null;
      return map;
    } catch (_) {
      return null;
    }
  }

  static bool isHangupAction(String? actionId) => actionId == actionHangup;

  static bool isReturnAction(String? actionId, String? payload) {
    if (actionId == actionHangup) return false;
    if (actionId == actionReturn) return true;
    return decode(payload) != null;
  }
}
