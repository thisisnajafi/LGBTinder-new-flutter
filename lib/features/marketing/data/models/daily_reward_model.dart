/// Daily reward status model
/// Part of the Marketing System Implementation (Task 3.1.4)
class DailyRewardStatus {
  final bool canClaimToday;
  final int currentStreak;
  final int longestStreak;
  final int currentDayInCycle;
  final DateTime? lastClaimDate;
  final List<DailyRewardConfig> rewards;
  final DailyRewardConfig? todayReward;
  final List<StreakBonus> availableBonuses;

  DailyRewardStatus({
    required this.canClaimToday,
    required this.currentStreak,
    required this.longestStreak,
    required this.currentDayInCycle,
    this.lastClaimDate,
    this.rewards = const [],
    this.todayReward,
    this.availableBonuses = const [],
  });

  factory DailyRewardStatus.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return DailyRewardStatus(
      canClaimToday: _parseBool(data['can_claim_today']),
      currentStreak: _parseInt(data['current_streak']) ?? 0,
      longestStreak: _parseInt(data['longest_streak']) ?? 0,
      currentDayInCycle: _parseInt(data['current_day_in_cycle']) ?? 1,
      lastClaimDate: _parseDateTime(data['last_claim_date']),
      rewards: (data['rewards'] as List?)
              ?.map((e) => DailyRewardConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      todayReward: data['today_reward'] != null
          ? DailyRewardConfig.fromJson(data['today_reward'] as Map<String, dynamic>)
          : null,
      availableBonuses: (data['available_bonuses'] as List?)
              ?.map((e) => StreakBonus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'can_claim_today': canClaimToday,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'current_day_in_cycle': currentDayInCycle,
      if (lastClaimDate != null) 'last_claim_date': lastClaimDate!.toIso8601String(),
      'rewards': rewards.map((e) => e.toJson()).toList(),
      if (todayReward != null) 'today_reward': todayReward!.toJson(),
      'available_bonuses': availableBonuses.map((e) => e.toJson()).toList(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Daily reward configuration for each day
class DailyRewardConfig {
  final int id;
  final int dayNumber;
  final String rewardType; // coins, superlikes, boosts, premium_days
  final int rewardAmount;
  final String? icon;
  final bool isClaimed;

  DailyRewardConfig({
    required this.id,
    required this.dayNumber,
    required this.rewardType,
    required this.rewardAmount,
    this.icon,
    this.isClaimed = false,
  });

  factory DailyRewardConfig.fromJson(Map<String, dynamic> json) {
    return DailyRewardConfig(
      id: _parseInt(json['id']) ?? 0,
      dayNumber: _parseInt(json['day_number']) ?? 1,
      rewardType: json['reward_type']?.toString() ?? 'coins',
      rewardAmount: _parseInt(json['reward_amount']) ?? 0,
      icon: json['icon']?.toString(),
      isClaimed: _parseBool(json['is_claimed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
      if (icon != null) 'icon': icon,
      'is_claimed': isClaimed,
    };
  }

  /// Get reward icon based on type
  String get rewardIcon {
    switch (rewardType) {
      case 'coins':
        return '🪙';
      case 'superlikes':
        return '⭐';
      case 'boosts':
        return '🚀';
      case 'premium_days':
        return '👑';
      default:
        return '🎁';
    }
  }

  /// Get formatted reward text
  String get rewardText {
    switch (rewardType) {
      case 'coins':
        return '$rewardAmount Coins';
      case 'superlikes':
        return '$rewardAmount Superlikes';
      case 'boosts':
        return '$rewardAmount Boosts';
      case 'premium_days':
        return '$rewardAmount Premium Days';
      default:
        return '$rewardAmount $rewardType';
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }
}

/// Streak bonus configuration
class StreakBonus {
  final int id;
  final int daysRequired;
  final String rewardType;
  final int rewardAmount;
  final bool isEarned;

  StreakBonus({
    required this.id,
    required this.daysRequired,
    required this.rewardType,
    required this.rewardAmount,
    this.isEarned = false,
  });

  factory StreakBonus.fromJson(Map<String, dynamic> json) {
    return StreakBonus(
      id: _parseInt(json['id']) ?? 0,
      daysRequired: _parseInt(json['days_required']) ?? 7,
      rewardType: json['reward_type']?.toString() ?? 'coins',
      rewardAmount: _parseInt(json['reward_amount']) ?? 0,
      isEarned: _parseBool(json['is_earned']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'days_required': daysRequired,
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
      'is_earned': isEarned,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return defaultValue;
  }
}

/// Result of claiming a daily reward
class ClaimResult {
  final bool success;
  final String message;
  final DailyRewardConfig? reward;
  final StreakBonus? bonusReward;
  final int newStreak;

  ClaimResult({
    required this.success,
    required this.message,
    this.reward,
    this.bonusReward,
    this.newStreak = 0,
  });

  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    return ClaimResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      reward: json['reward'] != null
          ? DailyRewardConfig.fromJson(json['reward'] as Map<String, dynamic>)
          : null,
      bonusReward: json['bonus_reward'] != null
          ? StreakBonus.fromJson(json['bonus_reward'] as Map<String, dynamic>)
          : null,
      newStreak: (json['new_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

