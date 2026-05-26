/// User sound preference values synced with the backend.
class SoundPreferences {
  final String messageSound;
  final String callRingtone;
  final String notificationSound;
  final bool vibrationEnabled;

  const SoundPreferences({
    this.messageSound = 'message_default',
    this.callRingtone = 'ringtone_default',
    this.notificationSound = 'message_default',
    this.vibrationEnabled = true,
  });

  factory SoundPreferences.fromJson(Map<String, dynamic> json) {
    return SoundPreferences(
      messageSound: json['message_sound']?.toString() ?? 'message_default',
      callRingtone: json['call_ringtone']?.toString() ?? 'ringtone_default',
      notificationSound:
          json['notification_sound']?.toString() ?? 'message_default',
      vibrationEnabled: json['vibration_enabled'] == true ||
          json['vibration_enabled'] == 1 ||
          json['vibration_enabled'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_sound': messageSound,
      'call_ringtone': callRingtone,
      'notification_sound': notificationSound,
      'vibration_enabled': vibrationEnabled,
    };
  }

  SoundPreferences copyWith({
    String? messageSound,
    String? callRingtone,
    String? notificationSound,
    bool? vibrationEnabled,
  }) {
    return SoundPreferences(
      messageSound: messageSound ?? this.messageSound,
      callRingtone: callRingtone ?? this.callRingtone,
      notificationSound: notificationSound ?? this.notificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

/// A selectable sound option from the catalog API.
class SoundOption {
  final String id;
  final String name;
  final String? asset;
  final String? androidRaw;

  const SoundOption({
    required this.id,
    required this.name,
    this.asset,
    this.androidRaw,
  });

  factory SoundOption.fromJson(Map<String, dynamic> json) {
    return SoundOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      asset: json['asset']?.toString(),
      androidRaw: json['android_raw']?.toString(),
    );
  }
}

/// Available sound catalog grouped by category.
class SoundCatalog {
  final List<SoundOption> messageSounds;
  final List<SoundOption> callRingtones;
  final List<SoundOption> notificationSounds;
  final SoundPreferences defaults;

  const SoundCatalog({
    this.messageSounds = const [],
    this.callRingtones = const [],
    this.notificationSounds = const [],
    this.defaults = const SoundPreferences(),
  });

  factory SoundCatalog.fromJson(Map<String, dynamic> json) {
    List<SoundOption> parseList(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => SoundOption.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return SoundCatalog(
      messageSounds: parseList(json['message_sounds']),
      callRingtones: parseList(json['call_ringtones']),
      notificationSounds: parseList(json['notification_sounds']),
      defaults: json['defaults'] is Map
          ? SoundPreferences.fromJson(
              Map<String, dynamic>.from(json['defaults'] as Map),
            )
          : const SoundPreferences(),
    );
  }

  SoundOption? findMessageSound(String id) {
    for (final item in messageSounds) {
      if (item.id == id) return item;
    }
    return null;
  }

  SoundOption? findCallRingtone(String id) {
    for (final item in callRingtones) {
      if (item.id == id) return item;
    }
    return null;
  }

  SoundOption? findNotificationSound(String id) {
    for (final item in notificationSounds) {
      if (item.id == id) return item;
    }
    return null;
  }
}

enum SoundCategory {
  message,
  call,
  notification,
}
