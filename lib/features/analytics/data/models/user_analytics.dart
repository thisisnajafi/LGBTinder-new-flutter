/// User analytics model
class UserAnalytics {
  final UserInfo userInfo;
  final EngagementMetrics engagementMetrics;
  final Map<String, int> activityBreakdown;
  final SessionAnalytics sessionAnalytics;
  final MatchingAnalytics matchingAnalytics;
  final CommunicationAnalytics communicationAnalytics;
  final ContentAnalytics contentAnalytics;
  final RevenueAnalytics revenueAnalytics;
  final RealTimeMetrics realTimeMetrics;

  UserAnalytics({
    required this.userInfo,
    required this.engagementMetrics,
    required this.activityBreakdown,
    required this.sessionAnalytics,
    required this.matchingAnalytics,
    required this.communicationAnalytics,
    required this.contentAnalytics,
    required this.revenueAnalytics,
    required this.realTimeMetrics,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      userInfo: UserInfo.fromJson(json['user_info'] ?? {}),
      engagementMetrics: EngagementMetrics.fromJson(json['engagement_metrics'] ?? {}),
      activityBreakdown: Map<String, int>.from(json['activity_breakdown'] ?? {}),
      sessionAnalytics: SessionAnalytics.fromJson(json['session_analytics'] ?? {}),
      matchingAnalytics: MatchingAnalytics.fromJson(json['matching_analytics'] ?? {}),
      communicationAnalytics: CommunicationAnalytics.fromJson(json['communication_analytics'] ?? {}),
      contentAnalytics: ContentAnalytics.fromJson(json['content_analytics'] ?? {}),
      revenueAnalytics: RevenueAnalytics.fromJson(json['revenue_analytics'] ?? {}),
      realTimeMetrics: RealTimeMetrics.fromJson(json['real_time_metrics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_info': userInfo.toJson(),
      'engagement_metrics': engagementMetrics.toJson(),
      'activity_breakdown': activityBreakdown,
      'session_analytics': sessionAnalytics.toJson(),
      'matching_analytics': matchingAnalytics.toJson(),
      'communication_analytics': communicationAnalytics.toJson(),
      'content_analytics': contentAnalytics.toJson(),
      'revenue_analytics': revenueAnalytics.toJson(),
      'real_time_metrics': realTimeMetrics.toJson(),
    };
  }
}

/// User info model
class UserInfo {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.lastSeenAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt!.toIso8601String(),
    };
  }
}

/// Engagement metrics model
class EngagementMetrics {
  final int totalSessions;
  final int totalSessionDuration;
  final double avgSessionDuration;
  final int totalActivities;
  final int dailyActiveDays;
  final double retentionRate;

  EngagementMetrics({
    required this.totalSessions,
    required this.totalSessionDuration,
    required this.avgSessionDuration,
    required this.totalActivities,
    required this.dailyActiveDays,
    required this.retentionRate,
  });

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EngagementMetrics(
      totalSessions: json['total_sessions'] ?? 0,
      totalSessionDuration: json['total_session_duration'] ?? 0,
      avgSessionDuration: (json['avg_session_duration'] ?? 0).toDouble(),
      totalActivities: json['total_activities'] ?? 0,
      dailyActiveDays: json['daily_active_days'] ?? 0,
      retentionRate: (json['retention_rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sessions': totalSessions,
      'total_session_duration': totalSessionDuration,
      'avg_session_duration': avgSessionDuration,
      'total_activities': totalActivities,
      'daily_active_days': dailyActiveDays,
      'retention_rate': retentionRate,
    };
  }
}

/// Session analytics model
class SessionAnalytics {
  final int totalSessions;
  final int totalDuration;
  final double avgDuration;
  final Map<String, int> sessionsByDay;
  final Map<String, int> sessionsByHour;

  SessionAnalytics({
    required this.totalSessions,
    required this.totalDuration,
    required this.avgDuration,
    required this.sessionsByDay,
    required this.sessionsByHour,
  });

  factory SessionAnalytics.fromJson(Map<String, dynamic> json) {
    return SessionAnalytics(
      totalSessions: json['total_sessions'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      avgDuration: (json['avg_duration'] ?? 0).toDouble(),
      sessionsByDay: Map<String, int>.from(json['sessions_by_day'] ?? {}),
      sessionsByHour: Map<String, int>.from(json['sessions_by_hour'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sessions': totalSessions,
      'total_duration': totalDuration,
      'avg_duration': avgDuration,
      'sessions_by_day': sessionsByDay,
      'sessions_by_hour': sessionsByHour,
    };
  }
}

/// Matching analytics model
class MatchingAnalytics {
  final int totalLikes;
  final int totalDislikes;
  final int totalSuperlikes;
  final int totalMatches;
  final double matchRate;
  final Map<String, int> likesByDay;

  MatchingAnalytics({
    required this.totalLikes,
    required this.totalDislikes,
    required this.totalSuperlikes,
    required this.totalMatches,
    required this.matchRate,
    required this.likesByDay,
  });

  factory MatchingAnalytics.fromJson(Map<String, dynamic> json) {
    return MatchingAnalytics(
      totalLikes: json['total_likes'] ?? 0,
      totalDislikes: json['total_dislikes'] ?? 0,
      totalSuperlikes: json['total_superlikes'] ?? 0,
      totalMatches: json['total_matches'] ?? 0,
      matchRate: (json['match_rate'] ?? 0).toDouble(),
      likesByDay: Map<String, int>.from(json['likes_by_day'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_likes': totalLikes,
      'total_dislikes': totalDislikes,
      'total_superlikes': totalSuperlikes,
      'total_matches': totalMatches,
      'match_rate': matchRate,
      'likes_by_day': likesByDay,
    };
  }
}

/// Communication analytics model
class CommunicationAnalytics {
  final int totalMessagesSent;
  final int totalMessagesReceived;
  final int totalMessagesRead;
  final int totalConversations;
  final double responseRate;
  final Map<String, int> messagesByDay;

  CommunicationAnalytics({
    required this.totalMessagesSent,
    required this.totalMessagesReceived,
    required this.totalMessagesRead,
    required this.totalConversations,
    required this.responseRate,
    required this.messagesByDay,
  });

  factory CommunicationAnalytics.fromJson(Map<String, dynamic> json) {
    return CommunicationAnalytics(
      totalMessagesSent: json['total_messages_sent'] ?? 0,
      totalMessagesReceived: json['total_messages_received'] ?? 0,
      totalMessagesRead: json['total_messages_read'] ?? 0,
      totalConversations: json['total_conversations'] ?? 0,
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      messagesByDay: Map<String, int>.from(json['messages_by_day'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_messages_sent': totalMessagesSent,
      'total_messages_received': totalMessagesReceived,
      'total_messages_read': totalMessagesRead,
      'total_conversations': totalConversations,
      'response_rate': responseRate,
      'messages_by_day': messagesByDay,
    };
  }
}

/// Content analytics model
class ContentAnalytics {
  final int totalStoriesCreated;
  final int totalStoriesViewed;
  final int totalPosts;
  final int totalComments;
  final int totalReactions;
  final Map<String, int> contentByDay;

  ContentAnalytics({
    required this.totalStoriesCreated,
    required this.totalStoriesViewed,
    required this.totalPosts,
    required this.totalComments,
    required this.totalReactions,
    required this.contentByDay,
  });

  factory ContentAnalytics.fromJson(Map<String, dynamic> json) {
    return ContentAnalytics(
      totalStoriesCreated: json['total_stories_created'] ?? 0,
      totalStoriesViewed: json['total_stories_viewed'] ?? 0,
      totalPosts: json['total_posts'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      totalReactions: json['total_reactions'] ?? 0,
      contentByDay: Map<String, int>.from(json['content_by_day'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_stories_created': totalStoriesCreated,
      'total_stories_viewed': totalStoriesViewed,
      'total_posts': totalPosts,
      'total_comments': totalComments,
      'total_reactions': totalReactions,
      'content_by_day': contentByDay,
    };
  }
}

/// Revenue analytics model
class RevenueAnalytics {
  final int totalPayments;
  final double totalSpent;
  final double avgPaymentAmount;
  final Map<String, int> paymentsByDay;
  final Map<String, double> spendingByCategory;

  RevenueAnalytics({
    required this.totalPayments,
    required this.totalSpent,
    required this.avgPaymentAmount,
    required this.paymentsByDay,
    required this.spendingByCategory,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      totalPayments: json['total_payments'] ?? 0,
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
      avgPaymentAmount: (json['avg_payment_amount'] ?? 0).toDouble(),
      paymentsByDay: Map<String, int>.from(json['payments_by_day'] ?? {}),
      spendingByCategory: Map<String, double>.from(json['spending_by_category'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_payments': totalPayments,
      'total_spent': totalSpent,
      'avg_payment_amount': avgPaymentAmount,
      'payments_by_day': paymentsByDay,
      'spending_by_category': spendingByCategory,
    };
  }
}

/// Real-time metrics model
class RealTimeMetrics {
  final int totalActivities;
  final Map<String, int> activitiesByType;
  final String? lastActivity;
  final String? lastActivityType;
  final int? totalLikes;
  final int? totalDislikes;
  final int? totalSuperlikes;
  final int? totalMatches;
  final int? totalMessagesSent;
  final int? totalMessagesRead;
  final int? totalStoriesViewed;
  final int? totalStoriesCreated;
  final int? totalPayments;
  final double? totalSpent;

  RealTimeMetrics({
    required this.totalActivities,
    required this.activitiesByType,
    this.lastActivity,
    this.lastActivityType,
    this.totalLikes,
    this.totalDislikes,
    this.totalSuperlikes,
    this.totalMatches,
    this.totalMessagesSent,
    this.totalMessagesRead,
    this.totalStoriesViewed,
    this.totalStoriesCreated,
    this.totalPayments,
    this.totalSpent,
  });

  factory RealTimeMetrics.fromJson(Map<String, dynamic> json) {
    return RealTimeMetrics(
      totalActivities: json['total_activities'] ?? 0,
      activitiesByType: Map<String, int>.from(json['activities_by_type'] ?? {}),
      lastActivity: json['last_activity'],
      lastActivityType: json['last_activity_type'],
      totalLikes: json['total_likes'],
      totalDislikes: json['total_dislikes'],
      totalSuperlikes: json['total_superlikes'],
      totalMatches: json['total_matches'],
      totalMessagesSent: json['total_messages_sent'],
      totalMessagesRead: json['total_messages_read'],
      totalStoriesViewed: json['total_stories_viewed'],
      totalStoriesCreated: json['total_stories_created'],
      totalPayments: json['total_payments'],
      totalSpent: json['total_spent']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_activities': totalActivities,
      'activities_by_type': activitiesByType,
      if (lastActivity != null) 'last_activity': lastActivity,
      if (lastActivityType != null) 'last_activity_type': lastActivityType,
      if (totalLikes != null) 'total_likes': totalLikes,
      if (totalDislikes != null) 'total_dislikes': totalDislikes,
      if (totalSuperlikes != null) 'total_superlikes': totalSuperlikes,
      if (totalMatches != null) 'total_matches': totalMatches,
      if (totalMessagesSent != null) 'total_messages_sent': totalMessagesSent,
      if (totalMessagesRead != null) 'total_messages_read': totalMessagesRead,
      if (totalStoriesViewed != null) 'total_stories_viewed': totalStoriesViewed,
      if (totalStoriesCreated != null) 'total_stories_created': totalStoriesCreated,
      if (totalPayments != null) 'total_payments': totalPayments,
      if (totalSpent != null) 'total_spent': totalSpent,
    };
  }
}
