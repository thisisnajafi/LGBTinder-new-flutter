/// Call settings update request model
import 'call_settings.dart';

class CallSettingsRequest {
  final bool videoEnabled;
  final bool audioEnabled;
  final bool speakerEnabled;
  final String? ringtone;
  final Map<String, dynamic>? preferences;

  CallSettingsRequest({
    required this.videoEnabled,
    required this.audioEnabled,
    required this.speakerEnabled,
    this.ringtone,
    this.preferences,
  });

  factory CallSettingsRequest.fromSettings(CallSettings settings) {
    return CallSettingsRequest(
      videoEnabled: settings.videoEnabled,
      audioEnabled: settings.audioEnabled,
      speakerEnabled: settings.speakerEnabled,
      ringtone: settings.ringtone,
      preferences: settings.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_enabled': videoEnabled,
      'audio_enabled': audioEnabled,
      'speaker_enabled': speakerEnabled,
      if (ringtone != null) 'ringtone': ringtone,
      if (preferences != null) 'preferences': preferences,
    };
  }
}
