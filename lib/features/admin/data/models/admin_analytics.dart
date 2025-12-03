/// Admin analytics model for dashboard statistics
class AdminAnalytics {
  final int totalUsers;
  final int activeUsersToday;
  final int activeUsersWeek;
  final int activeUsersMonth;
  final int newUsersToday;
  final int newUsersWeek;
  final int newUsersMonth;
  final int totalMatches;
  final int matchesToday;
  final int matchesWeek;
  final int totalMessages;
  final int messagesToday;
  final int messagesWeek;
  final int totalReports;
  final int pendingReports;
  final int resolvedReportsToday;
  final double revenueToday;
  final double revenueWeek;
  final double revenueMonth;
  final int premiumUsers;
  final int expiredSubscriptions;
  final Map<String, int> usersByCountry;
  final Map<String, int> usersByAge;
  final Map<String, int> usersByGender;
  final List<DailyStats> dailyStats;
  final DateTime lastUpdated;

  AdminAnalytics({
    required this.totalUsers,
    required this.activeUsersToday,
    required this.activeUsersWeek,
    required this.activeUsersMonth,
    required this.newUsersToday,
    required this.newUsersWeek,
    required this.newUsersMonth,
    required this.totalMatches,
    required this.matchesToday,
    required this.matchesWeek,
    required this.totalMessages,
    required this.messagesToday,
    required this.messagesWeek,
    required this.totalReports,
    required this.pendingReports,
    required this.resolvedReportsToday,
    required this.revenueToday,
    required this.revenueWeek,
    required this.revenueMonth,
    required this.premiumUsers,
    required this.expiredSubscriptions,
    required this.usersByCountry,
    required this.usersByAge,
    required this.usersByGender,
    required this.dailyStats,
    required this.lastUpdated,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsersToday: json['active_users_today'] as int? ?? 0,
      activeUsersWeek: json['active_users_week'] as int? ?? 0,
      activeUsersMonth: json['active_users_month'] as int? ?? 0,
      newUsersToday: json['new_users_today'] as int? ?? 0,
      newUsersWeek: json['new_users_week'] as int? ?? 0,
      newUsersMonth: json['new_users_month'] as int? ?? 0,
      totalMatches: json['total_matches'] as int? ?? 0,
      matchesToday: json['matches_today'] as int? ?? 0,
      matchesWeek: json['matches_week'] as int? ?? 0,
      totalMessages: json['total_messages'] as int? ?? 0,
      messagesToday: json['messages_today'] as int? ?? 0,
      messagesWeek: json['messages_week'] as int? ?? 0,
      totalReports: json['total_reports'] as int? ?? 0,
      pendingReports: json['pending_reports'] as int? ?? 0,
      resolvedReportsToday: json['resolved_reports_today'] as int? ?? 0,
      revenueToday: (json['revenue_today'] as num?)?.toDouble() ?? 0.0,
      revenueWeek: (json['revenue_week'] as num?)?.toDouble() ?? 0.0,
      revenueMonth: (json['revenue_month'] as num?)?.toDouble() ?? 0.0,
      premiumUsers: json['premium_users'] as int? ?? 0,
      expiredSubscriptions: json['expired_subscriptions'] as int? ?? 0,
      usersByCountry: json['users_by_country'] != null
          ? Map<String, int>.from(json['users_by_country'] as Map)
          : {},
      usersByAge: json['users_by_age'] != null
          ? Map<String, int>.from(json['users_by_age'] as Map)
          : {},
      usersByGender: json['users_by_gender'] != null
          ? Map<String, int>.from(json['users_by_gender'] as Map)
          : {},
      dailyStats: json['daily_stats'] != null
          ? (json['daily_stats'] as List)
              .map((e) => DailyStats.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_users_today': activeUsersToday,
      'active_users_week': activeUsersWeek,
      'active_users_month': activeUsersMonth,
      'new_users_today': newUsersToday,
      'new_users_week': newUsersWeek,
      'new_users_month': newUsersMonth,
      'total_matches': totalMatches,
      'matches_today': matchesToday,
      'matches_week': matchesWeek,
      'total_messages': totalMessages,
      'messages_today': messagesToday,
      'messages_week': messagesWeek,
      'total_reports': totalReports,
      'pending_reports': pendingReports,
      'resolved_reports_today': resolvedReportsToday,
      'revenue_today': revenueToday,
      'revenue_week': revenueWeek,
      'revenue_month': revenueMonth,
      'premium_users': premiumUsers,
      'expired_subscriptions': expiredSubscriptions,
      'users_by_country': usersByCountry,
      'users_by_age': usersByAge,
      'users_by_gender': usersByGender,
      'daily_stats': dailyStats.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Get user growth percentage compared to previous period
  double get userGrowthToday {
    if (dailyStats.length < 2) return 0.0;
    final today = dailyStats.last.newUsers;
    final yesterday = dailyStats[dailyStats.length - 2].newUsers;
    if (yesterday == 0) return 100.0;
    return ((today - yesterday) / yesterday) * 100;
  }

  /// Get match rate percentage
  double get matchRate {
    if (totalUsers == 0) return 0.0;
    return (totalMatches / totalUsers) * 100;
  }

  /// Get message rate percentage
  double get messageRate {
    if (totalUsers == 0) return 0.0;
    return (totalMessages / totalUsers) * 100;
  }

  /// Get revenue growth percentage
  double get revenueGrowth {
    if (dailyStats.length < 2) return 0.0;
    final today = dailyStats.last.revenue;
    final yesterday = dailyStats[dailyStats.length - 2].revenue;
    if (yesterday == 0) return 100.0;
    return ((today - yesterday) / yesterday) * 100;
  }
}

/// Daily statistics model
class DailyStats {
  final DateTime date;
  final int newUsers;
  final int activeUsers;
  final int matches;
  final int messages;
  final int reports;
  final double revenue;

  DailyStats({
    required this.date,
    required this.newUsers,
    required this.activeUsers,
    required this.matches,
    required this.messages,
    required this.reports,
    required this.revenue,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      newUsers: json['new_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      matches: json['matches'] as int? ?? 0,
      messages: json['messages'] as int? ?? 0,
      reports: json['reports'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'new_users': newUsers,
      'active_users': activeUsers,
      'matches': matches,
      'messages': messages,
      'reports': reports,
      'revenue': revenue,
    };
  }
}

/// Analytics filter model
class AnalyticsFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? country;
  final String? userType; // 'all', 'premium', 'free'
  final String? gender;
  final int? minAge;
  final int? maxAge;

  AnalyticsFilter({
    this.startDate,
    this.endDate,
    this.country,
    this.userType,
    this.gender,
    this.minAge,
    this.maxAge,
  });

  Map<String, dynamic> toJson() {
    return {
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (country != null) 'country': country,
      if (userType != null) 'user_type': userType,
      if (gender != null) 'gender': gender,
      if (minAge != null) 'min_age': minAge,
      if (maxAge != null) 'max_age': maxAge,
    };
  }
}

/// Export analytics request
class ExportAnalyticsRequest {
  final AnalyticsFilter filter;
  final String format; // 'csv', 'json', 'pdf'
  final List<String> metrics;

  ExportAnalyticsRequest({
    required this.filter,
    required this.format,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'filter': filter.toJson(),
      'format': format,
      'metrics': metrics,
    };
  }
}
