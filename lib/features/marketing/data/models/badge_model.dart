/// Badge/Achievement model
/// Part of the Marketing System Implementation (Task 3.1.5)
class BadgeModel {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String category; // engagement, social, premium, special
  final String rarity; // common, rare, epic, legendary
  final int points;
  final Map<String, dynamic>? criteria;
  final bool isDisplayed;
  final DateTime? earnedAt;
  final bool isRewardClaimed;

  BadgeModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.category,
    required this.rarity,
    required this.points,
    this.criteria,
    this.isDisplayed = false,
    this.earnedAt,
    this.isRewardClaimed = false,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      category: json['category']?.toString() ?? 'engagement',
      rarity: json['rarity']?.toString() ?? 'common',
      points: _parseInt(json['points']) ?? 0,
      criteria: json['criteria'] as Map<String, dynamic>?,
      isDisplayed: _parseBool(json['is_displayed']),
      earnedAt: _parseDateTime(json['earned_at']),
      isRewardClaimed: _parseBool(json['is_reward_claimed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      'category': category,
      'rarity': rarity,
      'points': points,
      if (criteria != null) 'criteria': criteria,
      'is_displayed': isDisplayed,
      if (earnedAt != null) 'earned_at': earnedAt!.toIso8601String(),
      'is_reward_claimed': isRewardClaimed,
    };
  }

  /// Check if badge has been earned
  bool get isEarned => earnedAt != null;

  /// Get rarity color (for UI)
  String get rarityColorHex {
    switch (rarity) {
      case 'legendary':
        return '#FFD700'; // Gold
      case 'epic':
        return '#9B59B6'; // Purple
      case 'rare':
        return '#3498DB'; // Blue
      default:
        return '#95A5A6'; // Gray
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Badge eligibility check result
class BadgeEligibility {
  final List<BadgeModel> eligible;
  final List<BadgeModel> inProgress;

  BadgeEligibility({
    this.eligible = const [],
    this.inProgress = const [],
  });

  factory BadgeEligibility.fromJson(Map<String, dynamic> json) {
    return BadgeEligibility(
      eligible: (json['eligible'] as List?)
              ?.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inProgress: (json['in_progress'] as List?)
              ?.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Badge progress for in-progress badges
class BadgeProgress {
  final int badgeId;
  final String badgeName;
  final int currentProgress;
  final int requiredProgress;
  final double percentage;

  BadgeProgress({
    required this.badgeId,
    required this.badgeName,
    required this.currentProgress,
    required this.requiredProgress,
    required this.percentage,
  });

  factory BadgeProgress.fromJson(Map<String, dynamic> json) {
    final current = (json['current_progress'] as num?)?.toInt() ?? 0;
    final required = (json['required_progress'] as num?)?.toInt() ?? 1;

    return BadgeProgress(
      badgeId: (json['badge_id'] as num?)?.toInt() ?? 0,
      badgeName: json['badge_name']?.toString() ?? '',
      currentProgress: current,
      requiredProgress: required,
      percentage: json['percentage'] != null
          ? (json['percentage'] as num).toDouble()
          : (current / required * 100).clamp(0, 100),
    );
  }
}

