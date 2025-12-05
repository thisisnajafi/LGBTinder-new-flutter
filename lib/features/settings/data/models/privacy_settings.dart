/// Privacy settings model
class PrivacySettings {
  final bool profileVisible;
  final bool showDistance;
  final bool showAge;
  final bool showOnlineStatus;
  final bool allowMessaging;
  final bool allowSuperLikes;
  final bool allowProfileViews;
  final bool hideFromDiscovery;
  final bool incognitoMode;
  final bool blockUnknownMessages;
  final bool requireVerification;
  final List<String> blockedWords;
  final bool dataCollection;
  final bool analyticsSharing;
  final bool locationSharing;
  final bool contactSync;
  final bool photoVerification;
  final String visibilityLevel; // 'public', 'matches', 'premium'
  final Map<String, bool> featureVisibility;

  PrivacySettings({
    this.profileVisible = true,
    this.showDistance = true,
    this.showAge = true,
    this.showOnlineStatus = true,
    this.allowMessaging = true,
    this.allowSuperLikes = true,
    this.allowProfileViews = true,
    this.hideFromDiscovery = false,
    this.incognitoMode = false,
    this.blockUnknownMessages = false,
    this.requireVerification = false,
    this.blockedWords = const [],
    this.dataCollection = true,
    this.analyticsSharing = false,
    this.locationSharing = true,
    this.contactSync = false,
    this.photoVerification = false,
    this.visibilityLevel = 'public',
    this.featureVisibility = const {},
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisible: json['profile_visible'] == true || json['profile_visible'] == 1 || json['profile_visible'] == null,
      showDistance: json['show_distance'] == true || json['show_distance'] == 1 || json['show_distance'] == null,
      showAge: json['show_age'] == true || json['show_age'] == 1 || json['show_age'] == null,
      showOnlineStatus: json['show_online_status'] == true || json['show_online_status'] == 1 || json['show_online_status'] == null,
      allowMessaging: json['allow_messaging'] == true || json['allow_messaging'] == 1 || json['allow_messaging'] == null,
      allowSuperLikes: json['allow_superlikes'] == true || json['allow_superlikes'] == 1 || json['allow_superlikes'] == null,
      allowProfileViews: json['allow_profile_views'] == true || json['allow_profile_views'] == 1 || json['allow_profile_views'] == null,
      hideFromDiscovery: json['hide_from_discovery'] == true || json['hide_from_discovery'] == 1,
      incognitoMode: json['incognito_mode'] == true || json['incognito_mode'] == 1,
      blockUnknownMessages: json['block_unknown_messages'] == true || json['block_unknown_messages'] == 1,
      requireVerification: json['require_verification'] == true || json['require_verification'] == 1,
      blockedWords: json['blocked_words'] != null && json['blocked_words'] is List
          ? (json['blocked_words'] as List).map((e) => e.toString()).toList()
          : [],
      dataCollection: json['data_collection'] == true || json['data_collection'] == 1 || json['data_collection'] == null,
      analyticsSharing: json['analytics_sharing'] == true || json['analytics_sharing'] == 1,
      locationSharing: json['location_sharing'] == true || json['location_sharing'] == 1 || json['location_sharing'] == null,
      contactSync: json['contact_sync'] == true || json['contact_sync'] == 1,
      photoVerification: json['photo_verification'] == true || json['photo_verification'] == 1,
      visibilityLevel: json['visibility_level']?.toString() ?? 'public',
      featureVisibility: json['feature_visibility'] != null && json['feature_visibility'] is Map
          ? Map<String, bool>.from((json['feature_visibility'] as Map).map((k, v) => MapEntry(k.toString(), v == true || v == 1)))
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_visible': profileVisible,
      'show_distance': showDistance,
      'show_age': showAge,
      'show_online_status': showOnlineStatus,
      'allow_messaging': allowMessaging,
      'allow_superlikes': allowSuperLikes,
      'allow_profile_views': allowProfileViews,
      'hide_from_discovery': hideFromDiscovery,
      'incognito_mode': incognitoMode,
      'block_unknown_messages': blockUnknownMessages,
      'require_verification': requireVerification,
      'blocked_words': blockedWords,
      'data_collection': dataCollection,
      'analytics_sharing': analyticsSharing,
      'location_sharing': locationSharing,
      'contact_sync': contactSync,
      'photo_verification': photoVerification,
      'visibility_level': visibilityLevel,
      'feature_visibility': featureVisibility,
    };
  }

  /// Create a copy with updated privacy settings
  PrivacySettings copyWith({
    bool? profileVisible,
    bool? showDistance,
    bool? showAge,
    bool? showOnlineStatus,
    bool? allowMessaging,
    bool? allowSuperLikes,
    bool? allowProfileViews,
    bool? hideFromDiscovery,
    bool? incognitoMode,
    bool? blockUnknownMessages,
    bool? requireVerification,
    List<String>? blockedWords,
    bool? dataCollection,
    bool? analyticsSharing,
    bool? locationSharing,
    bool? contactSync,
    bool? photoVerification,
    String? visibilityLevel,
    Map<String, bool>? featureVisibility,
  }) {
    return PrivacySettings(
      profileVisible: profileVisible ?? this.profileVisible,
      showDistance: showDistance ?? this.showDistance,
      showAge: showAge ?? this.showAge,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowMessaging: allowMessaging ?? this.allowMessaging,
      allowSuperLikes: allowSuperLikes ?? this.allowSuperLikes,
      allowProfileViews: allowProfileViews ?? this.allowProfileViews,
      hideFromDiscovery: hideFromDiscovery ?? this.hideFromDiscovery,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      blockUnknownMessages: blockUnknownMessages ?? this.blockUnknownMessages,
      requireVerification: requireVerification ?? this.requireVerification,
      blockedWords: blockedWords ?? this.blockedWords,
      dataCollection: dataCollection ?? this.dataCollection,
      analyticsSharing: analyticsSharing ?? this.analyticsSharing,
      locationSharing: locationSharing ?? this.locationSharing,
      contactSync: contactSync ?? this.contactSync,
      photoVerification: photoVerification ?? this.photoVerification,
      visibilityLevel: visibilityLevel ?? this.visibilityLevel,
      featureVisibility: featureVisibility ?? this.featureVisibility,
    );
  }

  /// Check if a message contains blocked words
  bool containsBlockedWords(String message) {
    if (blockedWords.isEmpty) return false;
    final lowerMessage = message.toLowerCase();
    return blockedWords.any((word) => lowerMessage.contains(word.toLowerCase()));
  }

  /// Check if user can be contacted
  bool canBeContacted() {
    return profileVisible && allowMessaging && !hideFromDiscovery;
  }

  /// Check if profile is visible in discovery
  bool isVisibleInDiscovery() {
    return profileVisible && !hideFromDiscovery && !incognitoMode;
  }
}

/// Update privacy settings request
class UpdatePrivacySettingsRequest {
  final PrivacySettings settings;

  UpdatePrivacySettingsRequest({required this.settings});

  Map<String, dynamic> toJson() {
    return {'privacy_settings': settings.toJson()};
  }
}
