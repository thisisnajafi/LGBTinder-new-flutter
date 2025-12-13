import '../../../../shared/services/api_service.dart';
import '../models/badge_model.dart';

/// Gamification service for badges and achievements
/// Part of the Marketing System Implementation (Task 3.2.4)
class GamificationService {
  final ApiService _apiService;

  GamificationService(this._apiService);

  /// Get all badges with user progress
  Future<List<BadgeModel>> getAllBadges() async {
    try {
      final response = await _apiService.get<dynamic>(
        GamificationEndpoints.allBadges,
      );

      final data = _extractData(response.data);
      if (data != null && data['badges'] is List) {
        return (data['badges'] as List)
            .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's earned badges
  Future<List<BadgeModel>> getMyBadges() async {
    try {
      final response = await _apiService.get<dynamic>(
        GamificationEndpoints.myBadges,
      );

      final data = _extractData(response.data);
      if (data != null && data['badges'] is List) {
        return (data['badges'] as List)
            .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get displayed badges (for profile)
  Future<List<BadgeModel>> getDisplayedBadges() async {
    try {
      final response = await _apiService.get<dynamic>(
        GamificationEndpoints.displayedBadges,
      );

      final data = _extractData(response.data);
      if (data != null && data['badges'] is List) {
        return (data['badges'] as List)
            .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Check badge eligibility
  Future<BadgeEligibility> checkEligibility() async {
    try {
      final response = await _apiService.get<dynamic>(
        GamificationEndpoints.eligibility,
      );

      final data = _extractData(response.data);
      if (data != null) {
        return BadgeEligibility.fromJson(data);
      }
      return BadgeEligibility();
    } catch (e) {
      rethrow;
    }
  }

  /// Claim eligible badges
  Future<ClaimBadgesResult> claimBadges() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        GamificationEndpoints.claim,
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ClaimBadgesResult.fromJson(response.data!);
      }
      return ClaimBadgesResult(
        success: false,
        message: response.message ?? 'Failed to claim badges',
      );
    } catch (e) {
      return ClaimBadgesResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Claim reward for a specific badge
  Future<ClaimRewardResult> claimReward(int badgeId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        GamificationEndpoints.claimReward,
        data: {'badge_id': badgeId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ClaimRewardResult.fromJson(response.data!);
      }
      return ClaimRewardResult(
        success: false,
        message: response.message ?? 'Failed to claim reward',
      );
    } catch (e) {
      return ClaimRewardResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Toggle badge display on profile
  Future<bool> toggleBadgeDisplay(int badgeId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        GamificationEndpoints.toggleDisplay,
        data: {'badge_id': badgeId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['is_displayed'] == true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Get badge leaderboard
  Future<List<BadgeLeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _apiService.get<dynamic>(
        '${GamificationEndpoints.leaderboard}?limit=$limit',
      );

      final data = _extractData(response.data);
      if (data != null && data['leaderboard'] is List) {
        return (data['leaderboard'] as List)
            .map((e) => BadgeLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get badges for a specific user (for viewing profiles)
  Future<List<BadgeModel>> getUserBadges(int userId) async {
    try {
      final response = await _apiService.get<dynamic>(
        '${GamificationEndpoints.userBadges}/$userId',
      );

      final data = _extractData(response.data);
      if (data != null && data['badges'] is List) {
        return (data['badges'] as List)
            .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic>? _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return responseData;
    }
    return null;
  }
}

/// Result of claiming badges
class ClaimBadgesResult {
  final bool success;
  final String message;
  final List<BadgeModel> claimedBadges;
  final int totalPoints;

  ClaimBadgesResult({
    required this.success,
    required this.message,
    this.claimedBadges = const [],
    this.totalPoints = 0,
  });

  factory ClaimBadgesResult.fromJson(Map<String, dynamic> json) {
    return ClaimBadgesResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      claimedBadges: (json['claimed_badges'] as List?)
              ?.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Result of claiming a badge reward
class ClaimRewardResult {
  final bool success;
  final String message;
  final String? rewardType;
  final int? rewardAmount;

  ClaimRewardResult({
    required this.success,
    required this.message,
    this.rewardType,
    this.rewardAmount,
  });

  factory ClaimRewardResult.fromJson(Map<String, dynamic> json) {
    return ClaimRewardResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      rewardType: json['reward_type']?.toString(),
      rewardAmount: (json['reward_amount'] as num?)?.toInt(),
    );
  }
}

/// Badge leaderboard entry
class BadgeLeaderboardEntry {
  final int rank;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int totalBadges;
  final int totalPoints;

  BadgeLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.totalBadges,
    required this.totalPoints,
  });

  factory BadgeLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return BadgeLeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name']?.toString() ?? 'Unknown',
      userAvatar: json['user_avatar']?.toString(),
      totalBadges: (json['total_badges'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Gamification API endpoints
class GamificationEndpoints {
  static const String allBadges = '/badges/all';
  static const String myBadges = '/badges/my';
  static const String displayedBadges = '/badges/displayed';
  static const String eligibility = '/badges/eligibility';
  static const String claim = '/badges/claim';
  static const String claimReward = '/badges/claim-reward';
  static const String toggleDisplay = '/badges/toggle-display';
  static const String leaderboard = '/badges/leaderboard';
  static const String userBadges = '/badges/user';
}
