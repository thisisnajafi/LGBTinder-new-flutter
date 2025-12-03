/// User preferences model - contains user's dating and app preferences
class UserPreferences {
  // Dating preferences
  final List<int>? preferredGenders;
  final List<int>? relationGoals;
  final int? minAgePreference;
  final int? maxAgePreference;
  final int? maxDistance; // in kilometers
  final bool? showMeOnApp;

  // Discovery settings
  final bool? globalDiscovery; // allow discovery worldwide
  final List<int>? blockedCountries; // countries to exclude
  final List<int>? blockedCities; // cities to exclude

  // Privacy settings
  final bool? showOnlineStatus;
  final bool? showLastSeen;
  final bool? showReadReceipts;
  final bool? allowProfileScreenshot;

  // Notification preferences (subset for profile)
  final bool? showDistanceInDiscovery;
  final bool? showAgeInDiscovery;

  // Advanced preferences
  final Map<String, dynamic>? customPreferences;

  UserPreferences({
    this.preferredGenders,
    this.relationGoals,
    this.minAgePreference,
    this.maxAgePreference,
    this.maxDistance,
    this.showMeOnApp = true,
    this.globalDiscovery = false,
    this.blockedCountries,
    this.blockedCities,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.showReadReceipts = true,
    this.allowProfileScreenshot = false,
    this.showDistanceInDiscovery = true,
    this.showAgeInDiscovery = true,
    this.customPreferences,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredGenders: json['preferred_genders'] != null
          ? (json['preferred_genders'] as List).map((e) => e as int).toList()
          : null,
      relationGoals: json['relation_goals'] != null
          ? (json['relation_goals'] as List).map((e) => e as int).toList()
          : null,
      minAgePreference: json['min_age_preference'] as int?,
      maxAgePreference: json['max_age_preference'] as int?,
      maxDistance: json['max_distance'] as int?,
      showMeOnApp: json['show_me_on_app'] as bool? ?? true,
      globalDiscovery: json['global_discovery'] as bool? ?? false,
      blockedCountries: json['blocked_countries'] != null
          ? (json['blocked_countries'] as List).map((e) => e as int).toList()
          : null,
      blockedCities: json['blocked_cities'] != null
          ? (json['blocked_cities'] as List).map((e) => e as int).toList()
          : null,
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      showLastSeen: json['show_last_seen'] as bool? ?? true,
      showReadReceipts: json['show_read_receipts'] as bool? ?? true,
      allowProfileScreenshot: json['allow_profile_screenshot'] as bool? ?? false,
      showDistanceInDiscovery: json['show_distance_in_discovery'] as bool? ?? true,
      showAgeInDiscovery: json['show_age_in_discovery'] as bool? ?? true,
      customPreferences: json['custom_preferences'] != null
          ? Map<String, dynamic>.from(json['custom_preferences'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (preferredGenders != null) 'preferred_genders': preferredGenders,
      if (relationGoals != null) 'relation_goals': relationGoals,
      if (minAgePreference != null) 'min_age_preference': minAgePreference,
      if (maxAgePreference != null) 'max_age_preference': maxAgePreference,
      if (maxDistance != null) 'max_distance': maxDistance,
      'show_me_on_app': showMeOnApp,
      'global_discovery': globalDiscovery,
      if (blockedCountries != null) 'blocked_countries': blockedCountries,
      if (blockedCities != null) 'blocked_cities': blockedCities,
      'show_online_status': showOnlineStatus,
      'show_last_seen': showLastSeen,
      'show_read_receipts': showReadReceipts,
      'allow_profile_screenshot': allowProfileScreenshot,
      'show_distance_in_discovery': showDistanceInDiscovery,
      'show_age_in_discovery': showAgeInDiscovery,
      if (customPreferences != null) 'custom_preferences': customPreferences,
    };
  }

  /// Create a copy with updated preferences
  UserPreferences copyWith({
    List<int>? preferredGenders,
    List<int>? relationGoals,
    int? minAgePreference,
    int? maxAgePreference,
    int? maxDistance,
    bool? showMeOnApp,
    bool? globalDiscovery,
    List<int>? blockedCountries,
    List<int>? blockedCities,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? showReadReceipts,
    bool? allowProfileScreenshot,
    bool? showDistanceInDiscovery,
    bool? showAgeInDiscovery,
    Map<String, dynamic>? customPreferences,
  }) {
    return UserPreferences(
      preferredGenders: preferredGenders ?? this.preferredGenders,
      relationGoals: relationGoals ?? this.relationGoals,
      minAgePreference: minAgePreference ?? this.minAgePreference,
      maxAgePreference: maxAgePreference ?? this.maxAgePreference,
      maxDistance: maxDistance ?? this.maxDistance,
      showMeOnApp: showMeOnApp ?? this.showMeOnApp,
      globalDiscovery: globalDiscovery ?? this.globalDiscovery,
      blockedCountries: blockedCountries ?? this.blockedCountries,
      blockedCities: blockedCities ?? this.blockedCities,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      allowProfileScreenshot: allowProfileScreenshot ?? this.allowProfileScreenshot,
      showDistanceInDiscovery: showDistanceInDiscovery ?? this.showDistanceInDiscovery,
      showAgeInDiscovery: showAgeInDiscovery ?? this.showAgeInDiscovery,
      customPreferences: customPreferences ?? this.customPreferences,
    );
  }

  /// Get formatted age range string
  String get ageRangeText {
    if (minAgePreference != null && maxAgePreference != null) {
      return '$minAgePreference - $maxAgePreference';
    } else if (minAgePreference != null) {
      return '$minAgePreference+';
    } else if (maxAgePreference != null) {
      return 'Up to $maxAgePreference';
    }
    return 'Any age';
  }

  /// Get formatted distance string
  String get distanceText {
    if (maxDistance != null) {
      return '$maxDistance km';
    }
    return 'Worldwide';
  }
}
