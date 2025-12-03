/// Call model representing a video/voice call
class Call {
  final int id;
  final int callerId;
  final int receiverId;
  final String callType; // 'video' or 'voice'
  final String status; // 'initiated', 'ringing', 'connected', 'ended', 'missed', 'rejected'
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration; // in seconds
  final String? token; // WebRTC token
  final String? channelName; // Agora/WebRTC channel
  final Map<String, dynamic>? metadata;

  Call({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration,
    this.token,
    this.channelName,
    this.metadata,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as int,
      callerId: json['caller_id'] as int,
      receiverId: json['receiver_id'] as int,
      callType: json['call_type'] as String,
      status: json['status'] as String,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      duration: json['duration'] as int?,
      token: json['token'] as String?,
      channelName: json['channel_name'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': callType,
      'status': status,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      if (duration != null) 'duration': duration,
      if (token != null) 'token': token,
      if (channelName != null) 'channel_name': channelName,
      if (metadata != null) 'metadata': metadata,
    };
  }

  bool get isActive => status == 'connected' || status == 'ringing';
  bool get isCompleted => status == 'ended' || status == 'missed' || status == 'rejected';
  bool get isVideoCall => callType == 'video';
  bool get isVoiceCall => callType == 'voice';
}
