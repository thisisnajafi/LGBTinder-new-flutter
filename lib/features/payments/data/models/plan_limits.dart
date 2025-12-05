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
  bool hasReachedLimit(String limitType) {
    switch (limitType) {
      case 'swipes':
        return usage.swipes.remaining <= 0 && !usage.swipes.isUnlimited;
      case 'likes':
        return usage.likes.remaining <= 0 && !usage.likes.isUnlimited;
      case 'superlikes':
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
      isPremium: json['is_premium'] as bool? ?? false,
      planName: json['plan_name'] as String? ?? 'Free',
      planId: json['plan_id'] as int?,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at'] as String) 
          : null,
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
      dailyLimit: json['daily_limit'] as int? ?? 0,
      isUnlimited: json['is_unlimited'] as bool? ?? false,
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
      maxConversations: json['max_conversations'] as int? ?? 0,
      isUnlimited: json['is_unlimited'] as bool? ?? false,
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
    return UsageDetail(
      usedToday: json['used_today'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
      isUnlimited: json['is_unlimited'] as bool? ?? false,
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
      sentToday: json['sent_today'] as int? ?? 0,
      activeConversations: json['active_conversations'] as int? ?? 0,
      conversationLimit: json['conversation_limit'] as int? ?? 0,
      isUnlimited: json['is_unlimited'] as bool? ?? false,
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
      advancedFilters: json['advanced_filters'] as bool? ?? false,
      seeWhoLikedMe: json['see_who_liked_me'] as bool? ?? false,
      rewind: json['rewind'] as bool? ?? false,
      passport: json['passport'] as bool? ?? false,
      boost: json['boost'] as bool? ?? false,
      readReceipts: json['read_receipts'] as bool? ?? false,
      videoCalls: json['video_calls'] as bool? ?? false,
      incognitoMode: json['incognito_mode'] as bool? ?? false,
      adFree: json['ad_free'] as bool? ?? false,
      priorityLikes: json['priority_likes'] as bool? ?? false,
      aiMatching: json['ai_matching'] as bool? ?? false,
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
      resetsAt: DateTime.parse(json['resets_at'] as String),
      checkedAt: DateTime.parse(json['checked_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resets_at': resetsAt.toIso8601String(),
      'checked_at': checkedAt.toIso8601String(),
    };
  }
}

