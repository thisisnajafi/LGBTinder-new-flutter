/// Profile summary (name, avatar) for settings overview
class SettingsSummaryProfile {
  final String displayName;
  final String? imageUrl;

  const SettingsSummaryProfile({
    this.displayName = 'User',
    this.imageUrl,
  });

  factory SettingsSummaryProfile.fromJson(Map<String, dynamic> json) {
    return SettingsSummaryProfile(
      displayName: json['display_name']?.toString() ?? json['displayName']?.toString() ?? 'User',
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

/// Account summary (email) for settings overview
class SettingsSummaryAccount {
  final String? email;

  const SettingsSummaryAccount({this.email});

  factory SettingsSummaryAccount.fromJson(Map<String, dynamic> json) {
    return SettingsSummaryAccount(
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {if (email != null) 'email': email};
}

/// Notifications summary for settings overview
class SettingsSummaryNotifications {
  final String subtitle;

  const SettingsSummaryNotifications({this.subtitle = 'Manage notification preferences'});

  factory SettingsSummaryNotifications.fromJson(Map<String, dynamic> json) {
    return SettingsSummaryNotifications(
      subtitle: json['subtitle']?.toString() ?? 'Manage notification preferences',
    );
  }

  Map<String, dynamic> toJson() => {'subtitle': subtitle};
}

/// Settings overview/summary (for overview screen)
class SettingsSummary {
  final SettingsSummaryProfile profile;
  final SettingsSummaryAccount account;
  final String discoverySubtitle;
  final SettingsSummaryNotifications notifications;
  final int? profileCompletionPercent;
  final int? unreadNotifications;
  final int? activeSessionsCount;
  final Map<String, dynamic>? preferences;

  const SettingsSummary({
    this.profile = const SettingsSummaryProfile(),
    this.account = const SettingsSummaryAccount(),
    this.discoverySubtitle = 'Age range, distance, who can see you',
    this.notifications = const SettingsSummaryNotifications(),
    this.profileCompletionPercent,
    this.unreadNotifications,
    this.activeSessionsCount,
    this.preferences,
  });

  factory SettingsSummary.fromJson(Map<String, dynamic> json) {
    return SettingsSummary(
      profile: json['profile'] is Map
          ? SettingsSummaryProfile.fromJson(Map<String, dynamic>.from(json['profile'] as Map))
          : const SettingsSummaryProfile(),
      account: json['account'] is Map
          ? SettingsSummaryAccount.fromJson(Map<String, dynamic>.from(json['account'] as Map))
          : const SettingsSummaryAccount(),
      discoverySubtitle:
          json['discovery_subtitle']?.toString() ?? json['discoverySubtitle']?.toString() ?? 'Age range, distance, who can see you',
      notifications: json['notifications'] is Map
          ? SettingsSummaryNotifications.fromJson(Map<String, dynamic>.from(json['notifications'] as Map))
          : const SettingsSummaryNotifications(),
      profileCompletionPercent: json['profile_completion_percent'] is int
          ? json['profile_completion_percent'] as int
          : int.tryParse(json['profile_completion_percent']?.toString() ?? ''),
      unreadNotifications: json['unread_notifications'] is int
          ? json['unread_notifications'] as int
          : int.tryParse(json['unread_notifications']?.toString() ?? ''),
      activeSessionsCount: json['active_sessions_count'] is int
          ? json['active_sessions_count'] as int
          : int.tryParse(json['active_sessions_count']?.toString() ?? ''),
      preferences: json['preferences'] is Map
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'account': account.toJson(),
      'discovery_subtitle': discoverySubtitle,
      'notifications': notifications.toJson(),
      if (profileCompletionPercent != null) 'profile_completion_percent': profileCompletionPercent,
      if (unreadNotifications != null) 'unread_notifications': unreadNotifications,
      if (activeSessionsCount != null) 'active_sessions_count': activeSessionsCount,
      if (preferences != null) 'preferences': preferences,
    };
  }
}
