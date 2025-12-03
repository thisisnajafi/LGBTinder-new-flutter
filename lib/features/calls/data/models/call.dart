/// Call model for voice and video calls
class Call {
  final int id;
  final String callId;
  final int callerId;
  final int receiverId;
  final String callType; // 'audio', 'video'
  final String status; // 'initiated', 'ringing', 'connected', 'ended', 'missed', 'declined'
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration? duration;
  final String? endReason; // 'completed', 'declined', 'network_error', 'user_ended', etc.
  final Map<String, dynamic> metadata;

  Call({
    required this.id,
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.endReason,
    this.metadata = const {},
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'] as int,
      callId: json['call_id'] as String,
      callerId: json['caller_id'] as int,
      receiverId: json['receiver_id'] as int,
      callType: json['call_type'] as String,
      status: json['status'] as String,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      endReason: json['end_reason'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'call_id': callId,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': callType,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      if (duration != null) 'duration': duration!.inSeconds,
      if (endReason != null) 'end_reason': endReason,
      'metadata': metadata,
    };
  }

  /// Check if call is active
  bool get isActive => status == 'connected';

  /// Check if call is incoming (for current user)
  bool isIncoming(int currentUserId) => receiverId == currentUserId;

  /// Check if call is outgoing (for current user)
  bool isOutgoing(int currentUserId) => callerId == currentUserId;

  /// Get other participant ID
  int getOtherParticipantId(int currentUserId) {
    return callerId == currentUserId ? receiverId : callerId;
  }

  /// Get call duration formatted
  String get formattedDuration {
    if (duration == null) return '00:00';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if call was missed
  bool get isMissed => status == 'missed';

  /// Check if call was declined
  bool get isDeclined => status == 'declined';

  /// Create a copy with updated fields
  Call copyWith({
    int? id,
    String? callId,
    int? callerId,
    int? receiverId,
    String? callType,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? duration,
    String? endReason,
    Map<String, dynamic>? metadata,
  }) {
    return Call(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      endReason: endReason ?? this.endReason,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Call participant model
class CallParticipant {
  final int userId;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final bool isPremium;
  final DateTime? lastSeen;

  CallParticipant({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.isPremium = false,
    this.lastSeen,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      userId: json['user_id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_online': isOnline,
      'is_premium': isPremium,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
    };
  }
}

/// Call settings model
class CallSettings {
  final bool enableVideo;
  final bool enableAudio;
  final String videoQuality; // 'low', 'medium', 'high'
  final String audioQuality; // 'low', 'medium', 'high'
  final bool enableBackgroundBlur;
  final bool showPreview;
  final int maxCallDuration; // in minutes, 0 = unlimited
  final bool autoAcceptFromMatches;
  final bool enableCallWaiting;
  final Map<String, dynamic> customSettings;

  CallSettings({
    this.enableVideo = true,
    this.enableAudio = true,
    this.videoQuality = 'medium',
    this.audioQuality = 'medium',
    this.enableBackgroundBlur = false,
    this.showPreview = true,
    this.maxCallDuration = 60, // 1 hour default
    this.autoAcceptFromMatches = false,
    this.enableCallWaiting = true,
    this.customSettings = const {},
  });

  factory CallSettings.fromJson(Map<String, dynamic> json) {
    return CallSettings(
      enableVideo: json['enable_video'] as bool? ?? true,
      enableAudio: json['enable_audio'] as bool? ?? true,
      videoQuality: json['video_quality'] as String? ?? 'medium',
      audioQuality: json['audio_quality'] as String? ?? 'medium',
      enableBackgroundBlur: json['enable_background_blur'] as bool? ?? false,
      showPreview: json['show_preview'] as bool? ?? true,
      maxCallDuration: json['max_call_duration'] as int? ?? 60,
      autoAcceptFromMatches: json['auto_accept_from_matches'] as bool? ?? false,
      enableCallWaiting: json['enable_call_waiting'] as bool? ?? true,
      customSettings: json['custom_settings'] != null
          ? Map<String, dynamic>.from(json['custom_settings'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_video': enableVideo,
      'enable_audio': enableAudio,
      'video_quality': videoQuality,
      'audio_quality': audioQuality,
      'enable_background_blur': enableBackgroundBlur,
      'show_preview': showPreview,
      'max_call_duration': maxCallDuration,
      'auto_accept_from_matches': autoAcceptFromMatches,
      'enable_call_waiting': enableCallWaiting,
      'custom_settings': customSettings,
    };
  }

  CallSettings copyWith({
    bool? enableVideo,
    bool? enableAudio,
    String? videoQuality,
    String? audioQuality,
    bool? enableBackgroundBlur,
    bool? showPreview,
    int? maxCallDuration,
    bool? autoAcceptFromMatches,
    bool? enableCallWaiting,
    Map<String, dynamic>? customSettings,
  }) {
    return CallSettings(
      enableVideo: enableVideo ?? this.enableVideo,
      enableAudio: enableAudio ?? this.enableAudio,
      videoQuality: videoQuality ?? this.videoQuality,
      audioQuality: audioQuality ?? this.audioQuality,
      enableBackgroundBlur: enableBackgroundBlur ?? this.enableBackgroundBlur,
      showPreview: showPreview ?? this.showPreview,
      maxCallDuration: maxCallDuration ?? this.maxCallDuration,
      autoAcceptFromMatches: autoAcceptFromMatches ?? this.autoAcceptFromMatches,
      enableCallWaiting: enableCallWaiting ?? this.enableCallWaiting,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Initiate call request
class InitiateCallRequest {
  final int receiverId;
  final String callType; // 'audio', 'video'
  final Map<String, dynamic> metadata;

  InitiateCallRequest({
    required this.receiverId,
    required this.callType,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'receiver_id': receiverId,
      'call_type': callType,
      'metadata': metadata,
    };
  }
}

/// Call action request
class CallActionRequest {
  final String callId;
  final String action; // 'accept', 'decline', 'end'
  final Map<String, dynamic> metadata;

  CallActionRequest({
    required this.callId,
    required this.action,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'action': action,
      'metadata': metadata,
    };
  }
}

/// Update call settings request
class UpdateCallSettingsRequest {
  final CallSettings settings;

  UpdateCallSettingsRequest({required this.settings});

  Map<String, dynamic> toJson() {
    return {'settings': settings.toJson()};
  }
}