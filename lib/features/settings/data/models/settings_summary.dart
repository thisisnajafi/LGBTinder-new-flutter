/// Profile part of settings summary (display name, avatar, etc.).
class SettingsSummaryProfile {
  final String displayName;

  const SettingsSummaryProfile({this.displayName = 'User'});

  factory SettingsSummaryProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SettingsSummaryProfile();
    final name = json['display_name']?.toString() ??
        json['name']?.toString() ??
        json['first_name']?.toString();
    final last = json['last_name']?.toString();
    final full = (name != null && name.isNotEmpty)
        ? (last != null && last.isNotEmpty ? '$name $last' : name)
        : 'User';
    return SettingsSummaryProfile(displayName: full);
  }
}

/// Account part of settings summary (email, etc.).
class SettingsSummaryAccount {
  final String? email;

  const SettingsSummaryAccount({this.email});

  factory SettingsSummaryAccount.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SettingsSummaryAccount();
    return SettingsSummaryAccount(
      email: json['email']?.toString(),
    );
  }
}

/// Notifications part of settings summary (subtitle for UI).
class SettingsSummaryNotifications {
  final String subtitle;

  const SettingsSummaryNotifications({
    this.subtitle = 'Manage notification preferences',
  });

  factory SettingsSummaryNotifications.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SettingsSummaryNotifications();
    return SettingsSummaryNotifications(
      subtitle: json['subtitle']?.toString() ?? 'Manage notification preferences',
    );
  }
}

/// Summary of user settings for the settings overview screen.
/// Aggregated from user settings and related endpoints.
class SettingsSummary {
  final bool hasProfile;
  final bool profileComplete;
  final int unreadNotifications;
  final bool twoFactorEnabled;
  final String? discoveryVisibility;
  final SettingsSummaryProfile profile;
  final SettingsSummaryAccount account;
  final SettingsSummaryNotifications notifications;

  const SettingsSummary({
    this.hasProfile = false,
    this.profileComplete = false,
    this.unreadNotifications = 0,
    this.twoFactorEnabled = false,
    this.discoveryVisibility,
    SettingsSummaryProfile? profile,
    SettingsSummaryAccount? account,
    SettingsSummaryNotifications? notifications,
  })  : profile = profile ?? const SettingsSummaryProfile(),
        account = account ?? const SettingsSummaryAccount(),
        notifications = notifications ?? const SettingsSummaryNotifications();

  /// Subtitle for discovery section (e.g. "Age range, distance, who can see you").
  String get discoverySubtitle {
    if (discoveryVisibility != null && discoveryVisibility!.isNotEmpty) {
      if (discoveryVisibility == 'everyone') return 'Visible to everyone · Age range, distance';
      if (discoveryVisibility == 'people_i_like') return 'Visible to people you like';
      if (discoveryVisibility == 'hidden') return 'Hidden from discovery';
    }
    return 'Age range, distance, who can see you';
  }

  factory SettingsSummary.fromJson(Map<String, dynamic> json) {
    return SettingsSummary(
      hasProfile: json['has_profile'] == true || json['has_profile'] == 1,
      profileComplete:
          json['profile_complete'] == true || json['profile_complete'] == 1,
      unreadNotifications: (json['unread_notifications'] is int)
          ? json['unread_notifications'] as int
          : int.tryParse(json['unread_notifications']?.toString() ?? '0') ?? 0,
      twoFactorEnabled:
          json['two_factor_enabled'] == true || json['two_factor_enabled'] == 1,
      discoveryVisibility: json['discovery_visibility']?.toString(),
      profile: SettingsSummaryProfile.fromJson(
        json['profile'] != null && json['profile'] is Map
            ? Map<String, dynamic>.from(json['profile'] as Map)
            : (json['first_name'] != null || json['display_name'] != null
                ? {
                    'display_name': json['display_name'] ?? json['first_name'],
                    'first_name': json['first_name'],
                    'last_name': json['last_name'],
                  }
                : null),
      ),
      account: SettingsSummaryAccount.fromJson(
        json['account'] != null && json['account'] is Map
            ? Map<String, dynamic>.from(json['account'] as Map)
            : (json['email'] != null ? {'email': json['email']} : null),
      ),
      notifications: SettingsSummaryNotifications.fromJson(
        json['notifications'] != null && json['notifications'] is Map
            ? Map<String, dynamic>.from(json['notifications'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_profile': hasProfile,
      'profile_complete': profileComplete,
      'unread_notifications': unreadNotifications,
      'two_factor_enabled': twoFactorEnabled,
      if (discoveryVisibility != null) 'discovery_visibility': discoveryVisibility,
      'profile': {'display_name': profile.displayName},
      if (account.email != null) 'account': {'email': account.email},
      'notifications': {'subtitle': notifications.subtitle},
    };
  }
}
