/// Safe type parsing helpers for call settings
/// FIXED: Task 5.2.1 - Added safe type parsing to prevent crashes
bool _safeParseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Call settings model for user call preferences
class CallSettings {
  final bool videoEnabled;
  final bool audioEnabled;
  final bool speakerEnabled;
  final String? ringtone;
  final int maxCallDuration; // in minutes
  final bool autoAcceptCalls;
  final Map<String, dynamic>? preferences;

  CallSettings({
    required this.videoEnabled,
    required this.audioEnabled,
    required this.speakerEnabled,
    this.ringtone,
    this.maxCallDuration = 60,
    this.autoAcceptCalls = false,
    this.preferences,
  });

  factory CallSettings.fromJson(Map<String, dynamic> json) {
    return CallSettings(
      videoEnabled: _safeParseBool(json['video_enabled'], defaultValue: true),
      audioEnabled: _safeParseBool(json['audio_enabled'], defaultValue: true),
      speakerEnabled: _safeParseBool(json['speaker_enabled']),
      ringtone: json['ringtone']?.toString(),
      maxCallDuration: _safeParseInt(json['max_call_duration'], defaultValue: 60),
      autoAcceptCalls: _safeParseBool(json['auto_accept_calls']),
      preferences: json['preferences'] != null && json['preferences'] is Map
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_enabled': videoEnabled,
      'audio_enabled': audioEnabled,
      'speaker_enabled': speakerEnabled,
      if (ringtone != null) 'ringtone': ringtone,
      'max_call_duration': maxCallDuration,
      'auto_accept_calls': autoAcceptCalls,
      if (preferences != null) 'preferences': preferences,
    };
  }

  CallSettings copyWith({
    bool? videoEnabled,
    bool? audioEnabled,
    bool? speakerEnabled,
    String? ringtone,
    int? maxCallDuration,
    bool? autoAcceptCalls,
    Map<String, dynamic>? preferences,
  }) {
    return CallSettings(
      videoEnabled: videoEnabled ?? this.videoEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      ringtone: ringtone ?? this.ringtone,
      maxCallDuration: maxCallDuration ?? this.maxCallDuration,
      autoAcceptCalls: autoAcceptCalls ?? this.autoAcceptCalls,
      preferences: preferences ?? this.preferences,
    );
  }
}
