/// Parsed incoming call payload (Pusher or push notification).
class IncomingCallData {
  final String callId;
  final String callType; // 'audio', 'video', 'voice'
  final int callerId;
  final String callerName;
  final String? callerAvatar;
  final String? channelName;

  const IncomingCallData({
    required this.callId,
    required this.callType,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    this.channelName,
  });

  bool get isVideo =>
      callType == 'video' ||
      callType.contains('video');

  /// Build from Pusher `call.incoming` or FCM/OneSignal data map.
  static IncomingCallData? fromPayload(Map<String, dynamic> raw) {
    final data = _unwrap(raw);
    if (data == null) return null;

    final caller = data['caller'];
    final callerMap = caller is Map<String, dynamic>
        ? caller
        : (caller is Map ? Map<String, dynamic>.from(caller) : null);

    final callId = data['call_id'] ?? data['callId'];
    if (callId == null) return null;

    final callType = (data['call_type'] ?? data['callType'] ?? 'audio').toString();

    final callerId = _parseInt(
      data['caller_id'] ??
          data['callerId'] ??
          data['user_id'] ??
          data['from_user_id'] ??
          callerMap?['id'],
    );
    if (callerId <= 0) return null;

    final callerName = (data['caller_name'] ??
            data['callerName'] ??
            data['user_name'] ??
            callerMap?['name'] ??
            'Unknown')
        .toString();

    final avatar = (data['caller_avatar'] ??
            data['callerAvatar'] ??
            data['avatar_url'] ??
            callerMap?['avatar_url'])
        ?.toString();

    return IncomingCallData(
      callId: callId.toString(),
      callType: callType,
      callerId: callerId,
      callerName: callerName,
      callerAvatar: avatar?.isNotEmpty == true ? avatar : null,
      channelName: (data['channel_name'] ??
              data['agora_channel'] ??
              data['channelName'])
          ?.toString(),
    );
  }

  static Map<String, dynamic>? _unwrap(Map<String, dynamic> raw) {
    if (raw['call_id'] != null || raw['callId'] != null) return raw;
    final nested = raw['data'] ?? raw['custom'] ?? raw['payload'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    if (raw['type']?.toString().startsWith('incoming_call') == true) return raw;
    return raw;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
