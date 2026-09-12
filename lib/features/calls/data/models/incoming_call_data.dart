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

  static bool isCallPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (_nonCallTypes.contains(type)) {
      return false;
    }
    if (type == 'call' ||
        type == 'incoming_call' ||
        type.startsWith('incoming_call')) {
      return true;
    }
    final status = data['status']?.toString().toLowerCase();
    if (status == 'ended' ||
        status == 'missed' ||
        status == 'rejected' ||
        status == 'declined' ||
        status == 'busy') {
      return false;
    }
    final hasCallId =
        data.containsKey('call_id') || data.containsKey('callId');
    if (!hasCallId) return false;
    final hasCaller = data['caller'] != null ||
        data['caller_id'] != null ||
        data['callerId'] != null ||
        data['from_user_id'] != null ||
        data['user_id'] != null;
    final hasCallType =
        data['call_type'] != null || data['callType'] != null;
    return hasCaller && hasCallType;
  }

  static const Set<String> _nonCallTypes = {
    'missed_call',
    'call_declined',
    'call_ended',
    'call_busy',
    'call_not_answered',
    'like',
    'match',
    'message',
    'chat',
    'new_message',
    'superlike',
  };

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

    final avatar = (data['primary_image_url'] ??
            callerMap?['primary_image_url'] ??
            data['caller_avatar'] ??
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

  /// Native CallKit / flutter_callkit_incoming extras that survive a new process.
  Map<String, dynamic> toExtras() {
    return {
      'callId': callId,
      'call_id': callId,
      'callerId': callerId,
      'caller_id': callerId,
      'callType': callType,
      'call_type': callType,
      'callerName': callerName,
      'caller_name': callerName,
      if (callerAvatar != null) 'callerAvatar': callerAvatar,
      if (callerAvatar != null) 'caller_avatar': callerAvatar,
      if (callerAvatar != null) 'avatar': callerAvatar,
      if (channelName != null) 'channelName': channelName,
      if (channelName != null) 'channel_name': channelName,
      if (channelName != null) 'agora_channel': channelName,
    };
  }

  /// Parse a CallKit event body or [FlutterCallkitIncoming.activeCalls] row.
  static IncomingCallData? fromCallKitMap(Map<dynamic, dynamic> raw) {
    final body = <String, dynamic>{};
    raw.forEach((key, value) {
      body[key.toString()] = value;
    });

    final extraRaw = body['extra'];
    final extra = extraRaw is Map
        ? Map<String, dynamic>.from(extraRaw)
        : <String, dynamic>{};

    final type = body['type'];
    final inferredType = extra['callType'] ??
        extra['call_type'] ??
        ((type == 1 || type == '1') ? 'video' : 'audio');

    return fromPayload({
      ...body,
      ...extra,
      'call_id': extra['callId'] ??
          extra['call_id'] ??
          body['id'] ??
          body['uuid'] ??
          body['handle'] ??
          body['callId'],
      'caller_id': extra['callerId'] ??
          extra['caller_id'] ??
          extra['user_id'] ??
          extra['from_user_id'] ??
          body['callerId'],
      'caller_name': extra['callerName'] ??
          extra['caller_name'] ??
          extra['user_name'] ??
          body['nameCaller'] ??
          body['callerName'],
      'call_type': inferredType,
      'caller_avatar': extra['callerAvatar'] ??
          extra['avatar'] ??
          extra['primary_image_url'] ??
          extra['caller_avatar'] ??
          body['avatar'],
      'channel_name': extra['channel_name'] ??
          extra['agora_channel'] ??
          extra['channelName'] ??
          body['channel_name'],
      'agora_channel': extra['agora_channel'] ??
          extra['channelName'] ??
          extra['channel_name'],
    });
  }

  /// Call id from Pusher / push payloads (`call_id`, `callId`, or nested `data`).
  static String? callIdFromPayload(Map<String, dynamic> raw) {
    final data = _unwrap(raw);
    final id = data?['call_id'] ?? data?['callId'];
    if (id == null) return null;
    final value = id.toString();
    return value.isEmpty ? null : value;
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
