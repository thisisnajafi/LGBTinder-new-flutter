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
      videoEnabled: json['video_enabled'] as bool? ?? true,
      audioEnabled: json['audio_enabled'] as bool? ?? true,
      speakerEnabled: json['speaker_enabled'] as bool? ?? false,
      ringtone: json['ringtone'] as String?,
      maxCallDuration: json['max_call_duration'] as int? ?? 60,
      autoAcceptCalls: json['auto_accept_calls'] as bool? ?? false,
      preferences: json['preferences'] as Map<String, dynamic>?,
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
