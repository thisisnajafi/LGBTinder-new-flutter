/// User settings model
class UserSettings {
  final String language;
  final String theme;
  final bool showOnlineStatus;
  final bool readReceipts;
  final bool typingIndicators;
  final int maxDistance;
  final String distanceUnit;
  final List<String> interests;
  final Map<String, dynamic> discoveryPreferences;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool marketingEmails;
  final String timezone;
  final String dateFormat;
  final String timeFormat;
  final bool twoFactorEnabled;
  final String? twoFactorMethod;
  final bool biometricEnabled;
  final bool hapticFeedback;
  final bool soundEffects;
  final int cacheSize;
  final bool autoBackup;
  final String backupFrequency;
  final Map<String, dynamic> customSettings;

  UserSettings({
    this.language = 'en',
    this.theme = 'system',
    this.showOnlineStatus = true,
    this.readReceipts = true,
    this.typingIndicators = true,
    this.maxDistance = 50,
    this.distanceUnit = 'km',
    this.interests = const [],
    this.discoveryPreferences = const {},
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.marketingEmails = false,
    this.timezone = 'UTC',
    this.dateFormat = 'MM/dd/yyyy',
    this.timeFormat = '12h',
    this.twoFactorEnabled = false,
    this.twoFactorMethod,
    this.biometricEnabled = false,
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.cacheSize = 100, // MB
    this.autoBackup = true,
    this.backupFrequency = 'weekly',
    this.customSettings = const {},
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      language: json['language'] as String? ?? 'en',
      theme: json['theme'] as String? ?? 'system',
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      readReceipts: json['read_receipts'] as bool? ?? true,
      typingIndicators: json['typing_indicators'] as bool? ?? true,
      maxDistance: json['max_distance'] as int? ?? 50,
      distanceUnit: json['distance_unit'] as String? ?? 'km',
      interests: json['interests'] != null
          ? (json['interests'] as List).map((e) => e.toString()).toList()
          : [],
      discoveryPreferences: json['discovery_preferences'] != null
          ? Map<String, dynamic>.from(json['discovery_preferences'] as Map)
          : {},
      emailNotifications: json['email_notifications'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      smsNotifications: json['sms_notifications'] as bool? ?? false,
      marketingEmails: json['marketing_emails'] as bool? ?? false,
      timezone: json['timezone'] as String? ?? 'UTC',
      dateFormat: json['date_format'] as String? ?? 'MM/dd/yyyy',
      timeFormat: json['time_format'] as String? ?? '12h',
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      twoFactorMethod: json['two_factor_method'] as String?,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      hapticFeedback: json['haptic_feedback'] as bool? ?? true,
      soundEffects: json['sound_effects'] as bool? ?? true,
      cacheSize: json['cache_size'] as int? ?? 100,
      autoBackup: json['auto_backup'] as bool? ?? true,
      backupFrequency: json['backup_frequency'] as String? ?? 'weekly',
      customSettings: json['custom_settings'] != null
          ? Map<String, dynamic>.from(json['custom_settings'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'theme': theme,
      'show_online_status': showOnlineStatus,
      'read_receipts': readReceipts,
      'typing_indicators': typingIndicators,
      'max_distance': maxDistance,
      'distance_unit': distanceUnit,
      'interests': interests,
      'discovery_preferences': discoveryPreferences,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'sms_notifications': smsNotifications,
      'marketing_emails': marketingEmails,
      'timezone': timezone,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'two_factor_enabled': twoFactorEnabled,
      if (twoFactorMethod != null) 'two_factor_method': twoFactorMethod,
      'biometric_enabled': biometricEnabled,
      'haptic_feedback': hapticFeedback,
      'sound_effects': soundEffects,
      'cache_size': cacheSize,
      'auto_backup': autoBackup,
      'backup_frequency': backupFrequency,
      'custom_settings': customSettings,
    };
  }

  /// Create a copy with updated settings
  UserSettings copyWith({
    String? language,
    String? theme,
    bool? showOnlineStatus,
    bool? readReceipts,
    bool? typingIndicators,
    int? maxDistance,
    String? distanceUnit,
    List<String>? interests,
    Map<String, dynamic>? discoveryPreferences,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? marketingEmails,
    String? timezone,
    String? dateFormat,
    String? timeFormat,
    bool? twoFactorEnabled,
    String? twoFactorMethod,
    bool? biometricEnabled,
    bool? hapticFeedback,
    bool? soundEffects,
    int? cacheSize,
    bool? autoBackup,
    String? backupFrequency,
    Map<String, dynamic>? customSettings,
  }) {
    return UserSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      readReceipts: readReceipts ?? this.readReceipts,
      typingIndicators: typingIndicators ?? this.typingIndicators,
      maxDistance: maxDistance ?? this.maxDistance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      interests: interests ?? this.interests,
      discoveryPreferences: discoveryPreferences ?? this.discoveryPreferences,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      timezone: timezone ?? this.timezone,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorMethod: twoFactorMethod ?? this.twoFactorMethod,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
      cacheSize: cacheSize ?? this.cacheSize,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Update settings request
class UpdateSettingsRequest {
  final UserSettings settings;

  UpdateSettingsRequest({required this.settings});

  Map<String, dynamic> toJson() {
    return {'settings': settings.toJson()};
  }
}
