/// Privacy settings model — §5.6 + backend GET/PUT `/privacy/settings`.
class PrivacySettings {
  final bool profileVisible;
  final bool showDistance;
  final bool showAge;
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool allowMessaging;
  final bool allowSuperLikes;
  final bool allowProfileViews;
  final bool hideFromDiscovery;
  final bool showInTopPicks;
  final bool allowSwipeBack;
  final bool incognitoMode;
  final bool blockUnknownMessages;
  final bool showReadReceipts;
  final bool requireVerification;
  final List<String> blockedWords;
  final bool dataCollection;
  final bool analyticsSharing;
  final bool adsSharing;
  final bool locationSharing;
  final bool contactSync;
  final bool photoVerification;
  final String visibilityLevel; // everyone | matches | premium
  final Map<String, bool> featureVisibility;

  PrivacySettings({
    this.profileVisible = true,
    this.showDistance = true,
    this.showAge = true,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.allowMessaging = true,
    this.allowSuperLikes = true,
    this.allowProfileViews = true,
    this.hideFromDiscovery = false,
    this.showInTopPicks = true,
    this.allowSwipeBack = false,
    this.incognitoMode = false,
    this.blockUnknownMessages = false,
    this.showReadReceipts = true,
    this.requireVerification = false,
    this.blockedWords = const [],
    this.dataCollection = true,
    this.analyticsSharing = false,
    this.adsSharing = false,
    this.locationSharing = true,
    this.contactSync = false,
    this.photoVerification = false,
    this.visibilityLevel = 'everyone',
    this.featureVisibility = const {},
  });

  bool get showInDiscovery => !hideFromDiscovery;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    final hide = _jsonBool(json['hide_from_discovery'], defaultWhenNull: false);
    final showIn = json.containsKey('show_in_discovery')
        ? _jsonBool(json['show_in_discovery'], defaultWhenNull: !hide)
        : !hide;
    return PrivacySettings(
      profileVisible: _jsonBool(json['profile_visible'], defaultWhenNull: true),
      showDistance: _jsonBool(json['show_distance'], defaultWhenNull: true),
      showAge: _jsonBool(json['show_age'], defaultWhenNull: true),
      showOnlineStatus:
          _jsonBool(json['show_online_status'], defaultWhenNull: true),
      showLastSeen: _jsonBool(json['show_last_seen'], defaultWhenNull: true),
      allowMessaging: _jsonBool(json['allow_messaging'], defaultWhenNull: true),
      allowSuperLikes:
          _jsonBool(json['allow_superlikes'], defaultWhenNull: true),
      allowProfileViews:
          _jsonBool(json['allow_profile_views'], defaultWhenNull: true),
      hideFromDiscovery: json.containsKey('hide_from_discovery')
          ? hide
          : !showIn,
      showInTopPicks:
          _jsonBool(json['show_in_top_picks'], defaultWhenNull: true),
      allowSwipeBack:
          _jsonBool(json['allow_swipe_back'], defaultWhenNull: false),
      incognitoMode: _jsonBool(json['incognito_mode'], defaultWhenNull: false),
      blockUnknownMessages:
          _jsonBool(json['block_unknown_messages'], defaultWhenNull: false),
      showReadReceipts: json.containsKey('show_read_receipts')
          ? _jsonBool(json['show_read_receipts'], defaultWhenNull: true)
          : _jsonBool(json['read_receipts'], defaultWhenNull: true),
      requireVerification:
          _jsonBool(json['require_verification'], defaultWhenNull: false),
      blockedWords: json['blocked_words'] is List
          ? (json['blocked_words'] as List).map((e) => e.toString()).toList()
          : const [],
      dataCollection: _jsonBool(json['data_collection'], defaultWhenNull: true),
      analyticsSharing:
          _jsonBool(json['analytics_sharing'], defaultWhenNull: false),
      adsSharing: _jsonBool(json['ads_sharing'], defaultWhenNull: false),
      locationSharing:
          _jsonBool(json['location_sharing'], defaultWhenNull: true),
      contactSync: _jsonBool(json['contact_sync'], defaultWhenNull: false),
      photoVerification:
          _jsonBool(json['photo_verification'], defaultWhenNull: false),
      visibilityLevel: _mapVisibility(
        json['visibility_level'] ?? json['profile_visibility'],
      ),
      featureVisibility:
          json['feature_visibility'] != null && json['feature_visibility'] is Map
              ? Map<String, bool>.from(
                  (json['feature_visibility'] as Map).map(
                    (k, v) => MapEntry(k.toString(), v == true || v == 1),
                  ),
                )
              : const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_visible': profileVisible,
      'show_distance': showDistance,
      'show_age': showAge,
      'show_online_status': showOnlineStatus,
      'show_last_seen': showLastSeen,
      'allow_messaging': allowMessaging,
      'allow_superlikes': allowSuperLikes,
      'allow_profile_views': allowProfileViews,
      'hide_from_discovery': hideFromDiscovery,
      'show_in_discovery': showInDiscovery,
      'show_in_top_picks': showInTopPicks,
      'allow_swipe_back': allowSwipeBack,
      'incognito_mode': incognitoMode,
      'block_unknown_messages': blockUnknownMessages,
      'read_receipts': showReadReceipts,
      'show_read_receipts': showReadReceipts,
      'require_verification': requireVerification,
      'blocked_words': blockedWords,
      'data_collection': dataCollection,
      'analytics_sharing': analyticsSharing,
      'ads_sharing': adsSharing,
      'location_sharing': locationSharing,
      'contact_sync': contactSync,
      'photo_verification': photoVerification,
      'visibility_level': visibilityLevel,
      'profile_visibility': visibilityLevel,
      'feature_visibility': featureVisibility,
    };
  }

  PrivacySettings copyWith({
    bool? profileVisible,
    bool? showDistance,
    bool? showAge,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? allowMessaging,
    bool? allowSuperLikes,
    bool? allowProfileViews,
    bool? hideFromDiscovery,
    bool? showInDiscovery,
    bool? showInTopPicks,
    bool? allowSwipeBack,
    bool? incognitoMode,
    bool? blockUnknownMessages,
    bool? showReadReceipts,
    bool? requireVerification,
    List<String>? blockedWords,
    bool? dataCollection,
    bool? analyticsSharing,
    bool? adsSharing,
    bool? locationSharing,
    bool? contactSync,
    bool? photoVerification,
    String? visibilityLevel,
    Map<String, bool>? featureVisibility,
  }) {
    final hide = hideFromDiscovery ??
        (showInDiscovery != null ? !showInDiscovery : this.hideFromDiscovery);
    return PrivacySettings(
      profileVisible: profileVisible ?? this.profileVisible,
      showDistance: showDistance ?? this.showDistance,
      showAge: showAge ?? this.showAge,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      allowMessaging: allowMessaging ?? this.allowMessaging,
      allowSuperLikes: allowSuperLikes ?? this.allowSuperLikes,
      allowProfileViews: allowProfileViews ?? this.allowProfileViews,
      hideFromDiscovery: hide,
      showInTopPicks: showInTopPicks ?? this.showInTopPicks,
      allowSwipeBack: allowSwipeBack ?? this.allowSwipeBack,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      blockUnknownMessages: blockUnknownMessages ?? this.blockUnknownMessages,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      requireVerification: requireVerification ?? this.requireVerification,
      blockedWords: blockedWords ?? this.blockedWords,
      dataCollection: dataCollection ?? this.dataCollection,
      analyticsSharing: analyticsSharing ?? this.analyticsSharing,
      adsSharing: adsSharing ?? this.adsSharing,
      locationSharing: locationSharing ?? this.locationSharing,
      contactSync: contactSync ?? this.contactSync,
      photoVerification: photoVerification ?? this.photoVerification,
      visibilityLevel: visibilityLevel != null
          ? _mapVisibility(visibilityLevel)
          : this.visibilityLevel,
      featureVisibility: featureVisibility ?? this.featureVisibility,
    );
  }

  bool containsBlockedWords(String message) {
    if (blockedWords.isEmpty) return false;
    final lowerMessage = message.toLowerCase();
    return blockedWords.any((word) => lowerMessage.contains(word.toLowerCase()));
  }

  bool canBeContacted() {
    return profileVisible && allowMessaging && !hideFromDiscovery;
  }

  bool isVisibleInDiscovery() {
    return profileVisible && !hideFromDiscovery && !incognitoMode;
  }

  static bool _jsonBool(dynamic value, {required bool defaultWhenNull}) {
    if (value == null) return defaultWhenNull;
    if (value is bool) return value;
    if (value is num) return value == 1;
    final normalized = value.toString().toLowerCase().trim();
    if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
      return true;
    }
    if (normalized == '0' || normalized == 'false' || normalized == 'no') {
      return false;
    }
    return defaultWhenNull;
  }

  static String _mapVisibility(dynamic raw) {
    switch (raw?.toString()) {
      case 'matches':
      case 'matches_only':
        return 'matches';
      case 'premium':
      case 'premium_only':
        return 'premium';
      default:
        return 'everyone';
    }
  }
}

class UpdatePrivacySettingsRequest {
  final PrivacySettings settings;

  UpdatePrivacySettingsRequest({required this.settings});

  Map<String, dynamic> toJson() {
    return {'privacy_settings': settings.toJson()};
  }
}
