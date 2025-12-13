import '../../../../shared/services/api_service.dart';
import '../models/daily_reward_model.dart';

/// Daily rewards service for streak management and reward claiming
/// Part of the Marketing System Implementation (Task 3.2.2)
class DailyRewardsService {
  final ApiService _apiService;

  DailyRewardsService(this._apiService);

  /// Get current daily reward status
  Future<DailyRewardStatus> getStatus() async {
    try {
      final response = await _apiService.get<dynamic>(
        DailyRewardsEndpoints.status,
      );

      final data = _extractData(response.data);
      if (data != null) {
        return DailyRewardStatus.fromJson(data);
      }
      return DailyRewardStatus(
        canClaimToday: false,
        currentStreak: 0,
        longestStreak: 0,
        currentDayInCycle: 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Claim today's reward
  Future<ClaimResult> claimReward() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        DailyRewardsEndpoints.claim,
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return ClaimResult.fromJson(response.data!);
      }
      return ClaimResult(
        success: false,
        message: response.message ?? 'Failed to claim reward',
      );
    } catch (e) {
      return ClaimResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Get reward configuration
  Future<List<DailyRewardConfig>> getConfiguration() async {
    try {
      final response = await _apiService.get<dynamic>(
        DailyRewardsEndpoints.config,
      );

      final data = _extractData(response.data);
      if (data != null && data['rewards'] is List) {
        return (data['rewards'] as List)
            .map((e) => DailyRewardConfig.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get claim history
  Future<List<DailyRewardClaim>> getHistory({int limit = 30}) async {
    try {
      final response = await _apiService.get<dynamic>(
        '${DailyRewardsEndpoints.history}?limit=$limit',
      );

      final data = _extractData(response.data);
      if (data != null && data['claims'] is List) {
        return (data['claims'] as List)
            .map((e) => DailyRewardClaim.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get leaderboard
  Future<List<StreakLeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _apiService.get<dynamic>(
        '${DailyRewardsEndpoints.leaderboard}?limit=$limit',
      );

      final data = _extractData(response.data);
      if (data != null && data['leaderboard'] is List) {
        return (data['leaderboard'] as List)
            .map((e) => StreakLeaderboardEntry.fromJson(e as Map<String, dynamic>))
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

/// Daily reward claim history entry
class DailyRewardClaim {
  final int id;
  final int dayNumber;
  final String rewardType;
  final int rewardAmount;
  final DateTime claimedAt;

  DailyRewardClaim({
    required this.id,
    required this.dayNumber,
    required this.rewardType,
    required this.rewardAmount,
    required this.claimedAt,
  });

  factory DailyRewardClaim.fromJson(Map<String, dynamic> json) {
    return DailyRewardClaim(
      id: (json['id'] as num?)?.toInt() ?? 0,
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      rewardType: json['reward_type']?.toString() ?? 'coins',
      rewardAmount: (json['reward_amount'] as num?)?.toInt() ?? 0,
      claimedAt: DateTime.tryParse(json['claimed_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Streak leaderboard entry
class StreakLeaderboardEntry {
  final int rank;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int currentStreak;
  final int longestStreak;

  StreakLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory StreakLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return StreakLeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name']?.toString() ?? 'Unknown',
      userAvatar: json['user_avatar']?.toString(),
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Daily rewards API endpoints
class DailyRewardsEndpoints {
  static const String status = '/daily-rewards/status';
  static const String claim = '/daily-rewards/claim';
  static const String config = '/daily-rewards/config';
  static const String history = '/daily-rewards/history';
  static const String leaderboard = '/daily-rewards/leaderboard';
}
