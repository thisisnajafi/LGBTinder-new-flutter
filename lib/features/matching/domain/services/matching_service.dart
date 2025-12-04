import '../../../core/constants/api_endpoints.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/network/dio_client.dart';
import '../../data/models/like.dart';
import '../../data/models/match.dart';
import '../../data/models/superlike.dart';
import '../../data/models/compatibility_score.dart';

/// Matching service for handling all matching-related API calls
class MatchingService {
  final ApiService _apiService;
  final DioClient _dioClient;

  MatchingService(
    this._apiService,
    this._dioClient,
  );

  /// Like a profile
  Future<LikeResponse> likeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesLike,
        data: {'user_id': profileId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null) {
        return LikeResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to like profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Dislike a profile
  Future<void> dislikeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesDislike,
        data: {'user_id': profileId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to dislike profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Superlike a profile
  Future<SuperlikeResponse> superlikeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesSuperlike,
        data: {'user_id': profileId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data != null) {
        return SuperlikeResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to superlike profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all matches
  Future<List<Match>> getMatches() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.likesMatches,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList.map((item) => Match.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get pending likes (likes received from others)
  Future<List<Like>> getPendingLikes() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.likesPending,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList.map((item) => Like.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get superlike history
  Future<List<Superlike>> getSuperlikeHistory() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.likesSuperlikeHistory,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList.map((item) => Superlike.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Check if current user is matched with another user
  Future<bool> checkMatchStatus(int targetUserId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        'profile/$targetUserId/match-status',
      );

      if (response.isSuccess && response.data != null && response.data!['is_matched'] != null) {
        return response.data!['is_matched'] as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get compatibility score between current user and target user
  Future<CompatibilityScore> getCompatibilityScore(int targetUserId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.matchingCompatibilityScore,
        queryParameters: {'target_user_id': targetUserId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CompatibilityScore.fromJson(response.data!);
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to get compatibility score');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Respond to a like (accept/reject)
  Future<void> respondToLike(int likeId, bool accept) async {
    try {
      final endpoint = accept ? ApiEndpoints.likesRespond : ApiEndpoints.likesRespond;
      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint,
        data: {'like_id': likeId, 'accept': accept},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to respond to like');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get match details
  Future<Match> getMatchDetails(int matchId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.likesMatches,
        queryParameters: {'match_id': matchId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return Match.fromJson(response.data!);
      } else {
        throw Exception(response.message.isNotEmpty
            ? response.message
            : 'Failed to get match details');
      }
    } catch (e) {
      rethrow;
    }
  }
}
