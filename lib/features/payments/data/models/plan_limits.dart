/// Safe type parsing helpers for plan limits
/// FIXED: Task 5.2.1 - Added safe type parsing to prevent crashes from backend type mismatches
class _SafeParser {
  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }
  
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Plan Limits Model
/// 
/// Contains all plan limits and current usage for the authenticated user
/// This allows the app to make UI decisions based on plan limits
class PlanLimits {
  final PlanInfo planInfo;
  final Limits limits;
  final Usage usage;
  final Features features;
  final Timestamps timestamps;

  PlanLimits({
    required this.planInfo,
    required this.limits,
    required this.usage,
    required this.features,
    required this.timestamps,
  });

  factory PlanLimits.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    
    return PlanLimits(
      planInfo: PlanInfo.fromJson(data['plan_info'] as Map<String, dynamic>),
      limits: Limits.fromJson(data['limits'] as Map<String, dynamic>),
      usage: Usage.fromJson(data['usage'] as Map<String, dynamic>),
      features: Features.fromJson(data['features'] as Map<String, dynamic>),
      timestamps: Timestamps.fromJson(data['timestamps'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_info': planInfo.toJson(),
      'limits': limits.toJson(),
      'usage': usage.toJson(),
      'features': features.toJson(),
      'timestamps': timestamps.toJson(),
    };
  }

  /// Check if user has reached a specific limit
  /// Logic: if user has used 0 today, they have not reached the limit (avoids backend returning wrong remaining).
  bool hasReachedLimit(String limitType) {
    switch (limitType) {
      case 'swipes':
        if (usage.swipes.usedToday == 0) return false;
        return usage.swipes.remaining <= 0 && !usage.swipes.isUnlimited;
      case 'likes':
        if (usage.likes.usedToday == 0) return false;
        return usage.likes.remaining <= 0 && !usage.likes.isUnlimited;
      case 'superlikes':
        if (usage.superlikes.usedToday == 0) return false;
        return usage.superlikes.remaining <= 0 && !usage.superlikes.isUnlimited;
      case 'messages':
        return !usage.messages.isUnlimited && 
               usage.messages.activeConversations >= usage.messages.conversationLimit;
      default:
        return false;
    }
  }

  /// Check if user has a specific feature
  bool hasFeature(String featureName) {
    switch (featureName) {
      case 'advanced_filters':
        return features.advancedFilters;
      case 'see_who_liked_me':
        return features.seeWhoLikedMe;
      case 'rewind':
        return features.rewind;
      case 'passport':
        return features.passport;
      case 'boost':
        return features.boost;
      case 'read_receipts':
        return features.readReceipts;
      case 'video_calls':
        return features.videoCalls;
      case 'incognito_mode':
        return features.incognitoMode;
      case 'ad_free':
        return features.adFree;
      case 'priority_likes':
        return features.priorityLikes;
      case 'ai_matching':
        return features.aiMatching;
      default:
        return false;
    }
  }
}

/// Plan Information
class PlanInfo {
  final bool isPremium;
  final String planName;
  final int? planId;
  final DateTime? expiresAt;

  PlanInfo({
    required this.isPremium,
    required this.planName,
    this.planId,
    this.expiresAt,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      isPremium: _SafeParser.parseBool(json['is_premium']),
      planName: json['plan_name']?.toString() ?? 'Free',
      planId: _SafeParser.parseInt(json['plan_id']),
      expiresAt: _SafeParser.parseDateTime(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_premium': isPremium,
      'plan_name': planName,
      'plan_id': planId,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}

/// Limits
class Limits {
  final LimitDetail swipes;
  final LimitDetail likes;
  final LimitDetail superlikes;
  final MessageLimitDetail messages;

  Limits({
    required this.swipes,
    required this.likes,
    required this.superlikes,
    required this.messages,
  });

  factory Limits.fromJson(Map<String, dynamic> json) {
    return Limits(
      swipes: LimitDetail.fromJson(json['swipes'] as Map<String, dynamic>),
      likes: LimitDetail.fromJson(json['likes'] as Map<String, dynamic>),
      superlikes: LimitDetail.fromJson(json['superlikes'] as Map<String, dynamic>),
      messages: MessageLimitDetail.fromJson(json['messages'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'swipes': swipes.toJson(),
      'likes': likes.toJson(),
      'superlikes': superlikes.toJson(),
      'messages': messages.toJson(),
    };
  }
}

/// Limit Detail
class LimitDetail {
  final int dailyLimit;
  final bool isUnlimited;

  LimitDetail({
    required this.dailyLimit,
    required this.isUnlimited,
  });

  factory LimitDetail.fromJson(Map<String, dynamic> json) {
    return LimitDetail(
      dailyLimit: _SafeParser.parseInt(json['daily_limit']),
      isUnlimited: _SafeParser.parseBool(json['is_unlimited']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_limit': dailyLimit,
      'is_unlimited': isUnlimited,
    };
  }
}

/// Message Limit Detail
class MessageLimitDetail {
  final int maxConversations;
  final bool isUnlimited;

  MessageLimitDetail({
    required this.maxConversations,
    required this.isUnlimited,
  });

  factory MessageLimitDetail.fromJson(Map<String, dynamic> json) {
    return MessageLimitDetail(
      maxConversations: _SafeParser.parseInt(json['max_conversations']),
      isUnlimited: _SafeParser.parseBool(json['is_unlimited']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'max_conversations': maxConversations,
      'is_unlimited': isUnlimited,
    };
  }
}

/// Usage
class Usage {
  final UsageDetail swipes;
  final UsageDetail likes;
  final UsageDetail superlikes;
  final MessageUsageDetail messages;

  Usage({
    required this.swipes,
    required this.likes,
    required this.superlikes,
    required this.messages,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      swipes: UsageDetail.fromJson(json['swipes'] as Map<String, dynamic>),
      likes: UsageDetail.fromJson(json['likes'] as Map<String, dynamic>),
      superlikes: UsageDetail.fromJson(json['superlikes'] as Map<String, dynamic>),
      messages: MessageUsageDetail.fromJson(json['messages'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'swipes': swipes.toJson(),
      'likes': likes.toJson(),
      'superlikes': superlikes.toJson(),
      'messages': messages.toJson(),
    };
  }
}

/// Usage Detail
class UsageDetail {
  final int usedToday;
  final int limit;
  final int remaining;
  final bool isUnlimited;

  UsageDetail({
    required this.usedToday,
    required this.limit,
    required this.remaining,
    required this.isUnlimited,
  });

  factory UsageDetail.fromJson(Map<String, dynamic> json) {
    final usedToday = _SafeParser.parseInt(json['used_today']);
    final limit = _SafeParser.parseInt(json['limit']);
    // If backend omits or sends wrong remaining, derive it so 0 swipes used = limit remaining
    int remaining = _SafeParser.parseInt(json['remaining'], defaultValue: -1);
    if (remaining < 0 && limit >= 0) {
      remaining = (limit - usedToday).clamp(0, limit);
    }
    return UsageDetail(
      usedToday: usedToday,
      limit: limit,
      remaining: remaining,
      isUnlimited: _SafeParser.parseBool(json['is_unlimited']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'used_today': usedToday,
      'limit': limit,
      'remaining': remaining,
      'is_unlimited': isUnlimited,
    };
  }
}

/// Message Usage Detail
class MessageUsageDetail {
  final int sentToday;
  final int activeConversations;
  final int conversationLimit;
  final bool isUnlimited;

  MessageUsageDetail({
    required this.sentToday,
    required this.activeConversations,
    required this.conversationLimit,
    required this.isUnlimited,
  });

  factory MessageUsageDetail.fromJson(Map<String, dynamic> json) {
    return MessageUsageDetail(
      sentToday: _SafeParser.parseInt(json['sent_today']),
      activeConversations: _SafeParser.parseInt(json['active_conversations']),
      conversationLimit: _SafeParser.parseInt(json['conversation_limit']),
      isUnlimited: _SafeParser.parseBool(json['is_unlimited']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sent_today': sentToday,
      'active_conversations': activeConversations,
      'conversation_limit': conversationLimit,
      'is_unlimited': isUnlimited,
    };
  }
}

/// Features
class Features {
  final bool advancedFilters;
  final bool seeWhoLikedMe;
  final bool rewind;
  final bool passport;
  final bool boost;
  final bool readReceipts;
  final bool videoCalls;
  final bool incognitoMode;
  final bool adFree;
  final bool priorityLikes;
  final bool aiMatching;

  Features({
    required this.advancedFilters,
    required this.seeWhoLikedMe,
    required this.rewind,
    required this.passport,
    required this.boost,
    required this.readReceipts,
    required this.videoCalls,
    required this.incognitoMode,
    required this.adFree,
    required this.priorityLikes,
    required this.aiMatching,
  });

  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      advancedFilters: _SafeParser.parseBool(json['advanced_filters']),
      seeWhoLikedMe: _SafeParser.parseBool(json['see_who_liked_me']),
      rewind: _SafeParser.parseBool(json['rewind']),
      passport: _SafeParser.parseBool(json['passport']),
      boost: _SafeParser.parseBool(json['boost']),
      readReceipts: _SafeParser.parseBool(json['read_receipts']),
      videoCalls: _SafeParser.parseBool(json['video_calls']),
      incognitoMode: _SafeParser.parseBool(json['incognito_mode']),
      adFree: _SafeParser.parseBool(json['ad_free']),
      priorityLikes: _SafeParser.parseBool(json['priority_likes']),
      aiMatching: _SafeParser.parseBool(json['ai_matching']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advanced_filters': advancedFilters,
      'see_who_liked_me': seeWhoLikedMe,
      'rewind': rewind,
      'passport': passport,
      'boost': boost,
      'read_receipts': readReceipts,
      'video_calls': videoCalls,
      'incognito_mode': incognitoMode,
      'ad_free': adFree,
      'priority_likes': priorityLikes,
      'ai_matching': aiMatching,
    };
  }
}

/// Timestamps
class Timestamps {
  final DateTime resetsAt;
  final DateTime checkedAt;

  Timestamps({
    required this.resetsAt,
    required this.checkedAt,
  });

  factory Timestamps.fromJson(Map<String, dynamic> json) {
    return Timestamps(
      resetsAt: _SafeParser.parseDateTime(json['resets_at']) ?? DateTime.now(),
      checkedAt: _SafeParser.parseDateTime(json['checked_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resets_at': resetsAt.toIso8601String(),
      'checked_at': checkedAt.toIso8601String(),
    };
  }
}

