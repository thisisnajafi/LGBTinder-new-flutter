import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/like.dart';
import '../models/match.dart';

/// Likes service for handling likes, dislikes, and superlikes
class LikesService {
  final ApiService _apiService;

  LikesService(this._apiService);

  /// Like a user
  Future<LikeResponse> likeUser(int likedUserId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesLike,
        data: LikeActionRequest(likedUserId: likedUserId).toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return LikeResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Dislike a user
  Future<void> dislikeUser(int likedUserId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesDislike,
        data: LikeActionRequest(likedUserId: likedUserId).toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Superlike a user
  Future<LikeResponse> superlikeUser(int likedUserId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesSuperlike,
        data: LikeActionRequest(likedUserId: likedUserId).toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return LikeResponse.fromJson(response.data!);
      } else {
        throw Exception(response.message);
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
  Future<List<Like>> getSuperlikeHistory() async {
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
        return dataList.map((item) => Like.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

