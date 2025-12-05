/// Notification preferences model
class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;

  // Push notification preferences
  final bool likes;
  final bool matches;
  final bool messages;
  final bool superlikes;
  final bool profileViews;
  final bool premiumFeatures;

  // Email preferences
  final bool weeklyDigest;
  final bool marketingEmails;
  final bool securityAlerts;

  // Quiet hours
  final bool quietHoursEnabled;
  final String? quietHoursStart; // HH:mm format
  final String? quietHoursEnd; // HH:mm format

  // Advanced settings
  final List<String> mutedUsers; // User IDs to mute notifications from
  final Map<String, bool> customPreferences;

  NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.likes = true,
    this.matches = true,
    this.messages = true,
    this.superlikes = true,
    this.profileViews = false,
    this.premiumFeatures = true,
    this.weeklyDigest = true,
    this.marketingEmails = false,
    this.securityAlerts = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.mutedUsers = const [],
    this.customPreferences = const {},
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['push_enabled'] == true || json['push_enabled'] == 1 || json['push_enabled'] == null,
      emailEnabled: json['email_enabled'] == true || json['email_enabled'] == 1 || json['email_enabled'] == null,
      smsEnabled: json['sms_enabled'] == true || json['sms_enabled'] == 1,
      likes: json['likes'] == true || json['likes'] == 1 || json['likes'] == null,
      matches: json['matches'] == true || json['matches'] == 1 || json['matches'] == null,
      messages: json['messages'] == true || json['messages'] == 1 || json['messages'] == null,
      superlikes: json['superlikes'] == true || json['superlikes'] == 1 || json['superlikes'] == null,
      profileViews: json['profile_views'] == true || json['profile_views'] == 1,
      premiumFeatures: json['premium_features'] == true || json['premium_features'] == 1 || json['premium_features'] == null,
      weeklyDigest: json['weekly_digest'] == true || json['weekly_digest'] == 1 || json['weekly_digest'] == null,
      marketingEmails: json['marketing_emails'] == true || json['marketing_emails'] == 1,
      securityAlerts: json['security_alerts'] == true || json['security_alerts'] == 1 || json['security_alerts'] == null,
      quietHoursEnabled: json['quiet_hours_enabled'] == true || json['quiet_hours_enabled'] == 1,
      quietHoursStart: json['quiet_hours_start']?.toString(),
      quietHoursEnd: json['quiet_hours_end']?.toString(),
      mutedUsers: json['muted_users'] != null && json['muted_users'] is List
          ? (json['muted_users'] as List).map((e) => e.toString()).toList()
          : [],
      customPreferences: json['custom_preferences'] != null && json['custom_preferences'] is Map
          ? Map<String, bool>.from((json['custom_preferences'] as Map).map((k, v) => MapEntry(k.toString(), v == true || v == 1)))
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'likes': likes,
      'matches': matches,
      'messages': messages,
      'superlikes': superlikes,
      'profile_views': profileViews,
      'premium_features': premiumFeatures,
      'weekly_digest': weeklyDigest,
      'marketing_emails': marketingEmails,
      'security_alerts': securityAlerts,
      'quiet_hours_enabled': quietHoursEnabled,
      if (quietHoursStart != null) 'quiet_hours_start': quietHoursStart,
      if (quietHoursEnd != null) 'quiet_hours_end': quietHoursEnd,
      'muted_users': mutedUsers,
      'custom_preferences': customPreferences,
    };
  }

  /// Check if notifications are allowed for a specific type during current time
  bool isNotificationAllowed(String type) {
    // Check if notification type is enabled
    switch (type) {
      case 'like':
        if (!likes) return false;
        break;
      case 'match':
        if (!matches) return false;
        break;
      case 'message':
        if (!messages) return false;
        break;
      case 'superlike':
        if (!superlikes) return false;
        break;
      case 'profile_view':
        if (!profileViews) return false;
        break;
      case 'premium':
        if (!premiumFeatures) return false;
        break;
    }

    // Check quiet hours
    if (quietHoursEnabled && _isInQuietHours()) {
      return false;
    }

    return pushEnabled;
  }

  bool _isInQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Simple time comparison (assuming same day)
    return currentTime.compareTo(quietHoursStart!) >= 0 &&
           currentTime.compareTo(quietHoursEnd!) <= 0;
  }

  /// Create a copy with updated preferences
  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? likes,
    bool? matches,
    bool? messages,
    bool? superlikes,
    bool? profileViews,
    bool? premiumFeatures,
    bool? weeklyDigest,
    bool? marketingEmails,
    bool? securityAlerts,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    List<String>? mutedUsers,
    Map<String, bool>? customPreferences,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      likes: likes ?? this.likes,
      matches: matches ?? this.matches,
      messages: messages ?? this.messages,
      superlikes: superlikes ?? this.superlikes,
      profileViews: profileViews ?? this.profileViews,
      premiumFeatures: premiumFeatures ?? this.premiumFeatures,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      customPreferences: customPreferences ?? this.customPreferences,
    );
  }
}

/// Update notification preferences request
class UpdateNotificationPreferencesRequest {
  final NotificationPreferences preferences;

  UpdateNotificationPreferencesRequest({required this.preferences});

  Map<String, dynamic> toJson() {
    return {'preferences': preferences.toJson()};
  }
}
