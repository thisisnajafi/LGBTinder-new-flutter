import '../../../auth/data/models/login_response.dart';

/// Safe type parsing helpers for call models
/// FIXED: Task 5.1.2, 5.1.3, 5.3.1 - Added safe type parsing to prevent crashes
class _TypeParser {
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }
  
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Call model for voice and video calls
/// FIXED: Task 5.3.1 - Removed strict validation that throws exceptions
class Call {
  final int id;
  final String callId;
  final int callerId;
  final int receiverId;
  final UserData? caller;
  final UserData? receiver;
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
    this.caller,
    this.receiver,
    required this.callType,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.endReason,
    this.metadata = const {},
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    // FIXED: Use safe parsing with defaults instead of throwing exceptions
    // This prevents list parsing from crashing on a single malformed item
    return Call(
      id: _TypeParser.parseInt(json['id']),
      callId: json['call_id']?.toString() ?? '',
      callerId: _TypeParser.parseInt(json['caller_id']),
      receiverId: _TypeParser.parseInt(json['receiver_id']),
      caller: json['caller'] != null && json['caller'] is Map
          ? UserData.fromJson(Map<String, dynamic>.from(json['caller'] as Map))
          : null,
      receiver: json['receiver'] != null && json['receiver'] is Map
          ? UserData.fromJson(Map<String, dynamic>.from(json['receiver'] as Map))
          : null,
      callType: json['call_type']?.toString() ?? 'audio',
      status: json['status']?.toString() ?? 'unknown',
      startedAt: _TypeParser.parseDateTime(json['started_at']) ?? DateTime.now(),
      endedAt: _TypeParser.parseDateTime(json['ended_at']),
      duration: json['duration'] != null
          ? Duration(seconds: _TypeParser.parseInt(json['duration']))
          : null,
      endReason: json['end_reason']?.toString(),
      metadata: json['metadata'] != null && json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
  
  /// Check if call data is valid (has required fields)
  bool get isValid => id > 0 && callId.isNotEmpty && callerId > 0 && receiverId > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'call_id': callId,
      'caller_id': callerId,
      'receiver_id': receiverId,
      if (caller != null) 'caller': caller!.toJson(),
      if (receiver != null) 'receiver': receiver!.toJson(),
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
    UserData? caller,
    UserData? receiver,
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
      caller: caller ?? this.caller,
      receiver: receiver ?? this.receiver,
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
/// FIXED: Task 5.3.1 - Removed strict validation that throws exceptions
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
    // FIXED: Use safe parsing with defaults instead of throwing exceptions
    return CallParticipant(
      userId: _TypeParser.parseInt(json['user_id']),
      name: json['name']?.toString() ?? 'Unknown',
      avatarUrl: json['avatar_url']?.toString(),
      isOnline: _TypeParser.parseBool(json['is_online']),
      isPremium: _TypeParser.parseBool(json['is_premium']),
      lastSeen: _TypeParser.parseDateTime(json['last_seen']),
    );
  }
  
  /// Check if participant data is valid
  bool get isValid => userId > 0;

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
/// FIXED: Task 5.1.2 - Updated fromJson to handle type casting safely
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
    // FIXED: Use safe type parsing instead of direct casting
    return CallSettings(
      enableVideo: _TypeParser.parseBool(json['enable_video'], defaultValue: true),
      enableAudio: _TypeParser.parseBool(json['enable_audio'], defaultValue: true),
      videoQuality: json['video_quality']?.toString() ?? 'medium',
      audioQuality: json['audio_quality']?.toString() ?? 'medium',
      enableBackgroundBlur: _TypeParser.parseBool(json['enable_background_blur']),
      showPreview: _TypeParser.parseBool(json['show_preview'], defaultValue: true),
      maxCallDuration: _TypeParser.parseInt(json['max_call_duration'], defaultValue: 60),
      autoAcceptFromMatches: _TypeParser.parseBool(json['auto_accept_from_matches']),
      enableCallWaiting: _TypeParser.parseBool(json['enable_call_waiting'], defaultValue: true),
      customSettings: json['custom_settings'] != null && json['custom_settings'] is Map
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


/// Update call settings request
class UpdateCallSettingsRequest {
  final CallSettings settings;

  UpdateCallSettingsRequest({required this.settings});

  Map<String, dynamic> toJson() {
    return {'settings': settings.toJson()};
  }
}