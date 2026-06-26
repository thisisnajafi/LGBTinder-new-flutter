import 'user_tier.dart';

/// Feature flags derived from the user's subscription plan.
class SubscriptionFeatures {
  final bool unlimitedLikes;
  final bool seeWhoLikedYou;
  final bool videoCallsEnabled;
  final bool advancedFilters;
  final bool profileBoost;
  final int? chatMessagesVisible;
  final int? messagesPerMatchDaily;

  const SubscriptionFeatures({
    required this.unlimitedLikes,
    required this.seeWhoLikedYou,
    required this.videoCallsEnabled,
    required this.advancedFilters,
    required this.profileBoost,
    this.chatMessagesVisible,
    this.messagesPerMatchDaily,
  });

  factory SubscriptionFeatures.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }

    return SubscriptionFeatures(
      unlimitedLikes: parseBool(json['unlimited_likes']),
      seeWhoLikedYou: parseBool(json['see_who_liked_you']),
      videoCallsEnabled: parseBool(json['video_calls']),
      advancedFilters: parseBool(json['advanced_filters']),
      profileBoost: parseBool(json['profile_boost']),
      chatMessagesVisible: parseNullableInt(json['chat_messages_visible']),
      messagesPerMatchDaily: parseNullableInt(json['messages_per_match_daily']),
    );
  }

  factory SubscriptionFeatures.free() => const SubscriptionFeatures(
        unlimitedLikes: false,
        seeWhoLikedYou: false,
        videoCallsEnabled: false,
        advancedFilters: false,
        profileBoost: false,
        chatMessagesVisible: 5,
        messagesPerMatchDaily: 10,
      );

  Map<String, dynamic> toJson() => {
        'unlimited_likes': unlimitedLikes,
        'see_who_liked_you': seeWhoLikedYou,
        'video_calls': videoCallsEnabled,
        'advanced_filters': advancedFilters,
        'profile_boost': profileBoost,
        'chat_messages_visible': chatMessagesVisible,
        'messages_per_match_daily': messagesPerMatchDaily,
      };

  @override
  bool operator ==(Object other) =>
      other is SubscriptionFeatures &&
      other.unlimitedLikes == unlimitedLikes &&
      other.seeWhoLikedYou == seeWhoLikedYou &&
      other.videoCallsEnabled == videoCallsEnabled &&
      other.advancedFilters == advancedFilters &&
      other.profileBoost == profileBoost &&
      other.chatMessagesVisible == chatMessagesVisible &&
      other.messagesPerMatchDaily == messagesPerMatchDaily;

  @override
  int get hashCode => Object.hash(
        unlimitedLikes,
        seeWhoLikedYou,
        videoCallsEnabled,
        advancedFilters,
        profileBoost,
        chatMessagesVisible,
        messagesPerMatchDaily,
      );
}

/// Global subscription state synced from API meta on every response.
class AppSubscriptionStatus {
  final UserTier tier;
  final bool isActive;
  final bool isPremium;
  final String? planName;
  final DateTime? expiresAt;
  final int superlikesRemaining;
  final DateTime? superlikesResetAt;
  final SubscriptionFeatures features;
  final DateTime refreshedAt;

  const AppSubscriptionStatus({
    required this.tier,
    required this.isActive,
    required this.isPremium,
    this.planName,
    this.expiresAt,
    required this.superlikesRemaining,
    this.superlikesResetAt,
    required this.features,
    required this.refreshedAt,
  });

  factory AppSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    final tierRaw = json['tier']?.toString().toLowerCase().trim() ?? 'basid';
    final tier = UserTier.values.firstWhere(
      (t) => t.key == tierRaw,
      orElse: () => UserTier.basid,
    );

    final featuresJson = json['features'];
    final features = featuresJson is Map<String, dynamic>
        ? SubscriptionFeatures.fromJson(featuresJson)
        : SubscriptionFeatures.free();

    return AppSubscriptionStatus(
      tier: tier,
      isActive: parseBool(json['is_active']),
      isPremium: parseBool(json['is_premium']),
      planName: json['plan_name']?.toString(),
      expiresAt: parseDate(json['expires_at'] ?? json['end_date']),
      superlikesRemaining: parseInt(json['superlikes_remaining']),
      superlikesResetAt: parseDate(json['superlikes_reset_at']),
      features: features,
      refreshedAt: parseDate(json['refreshed_at']) ?? DateTime.now(),
    );
  }

  factory AppSubscriptionStatus.free() => AppSubscriptionStatus(
        tier: UserTier.basid,
        isActive: false,
        isPremium: false,
        features: SubscriptionFeatures.free(),
        superlikesRemaining: 0,
        refreshedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'tier': tier.key,
        'is_active': isActive,
        'is_premium': isPremium,
        if (planName != null) 'plan_name': planName,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
        'superlikes_remaining': superlikesRemaining,
        if (superlikesResetAt != null)
          'superlikes_reset_at': superlikesResetAt!.toIso8601String(),
        'features': features.toJson(),
        'refreshed_at': refreshedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is AppSubscriptionStatus &&
      other.tier == tier &&
      other.isActive == isActive &&
      other.isPremium == isPremium &&
      other.superlikesRemaining == superlikesRemaining;

  @override
  int get hashCode =>
      Object.hash(tier, isActive, isPremium, superlikesRemaining);
}
