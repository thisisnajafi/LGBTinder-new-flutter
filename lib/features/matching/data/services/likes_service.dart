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
        deduplicateIdempotent: true,
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

  /// Dislike a user. Returns [DislikeResponse] with [theyLikedYou] when the other user had liked us.
  Future<DislikeResponse> dislikeUser(int likedUserId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesDislike,
        data: LikeActionRequest(likedUserId: likedUserId).toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
        deduplicateIdempotent: true,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        final theyLikedYou = data['they_liked_you'] == true;
        return DislikeResponse(theyLikedYou: theyLikedYou);
      }
      return DislikeResponse(theyLikedYou: false);
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
        deduplicateIdempotent: true,
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

  /// POST matches/dislike. Body: disliked_user_id. Alternative to likes/dislike.
  Future<Map<String, dynamic>> matchDislike(int dislikedUserId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.matchesDislike,
      data: {'disliked_user_id': dislikedUserId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST matches/superlike. Body: superliked_user_id. Alternative to likes/superlike.
  Future<Map<String, dynamic>> matchSuperlike(int superlikedUserId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.matchesSuperlike,
      data: {'superliked_user_id': superlikedUserId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Rewind (undo) the last like or dislike. Premium only. Returns restored user map or null.
  /// Backend: POST /api/likes/rewind; 403 REWIND_PREMIUM_REQUIRED, 404 NOTHING_TO_REWIND.
  Future<RewindResponse> rewind() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesRewind,
        data: <String, dynamic>{},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final restored = data['restored_user'] as Map<String, dynamic>?;
        return RewindResponse(
          restoredUser: restored,
          actionUndone: data['action_undone']?.toString(),
          remainingRewinds: data['remaining_rewinds'] as int?,
        );
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get matches count (API: GET likes/matches/count). Returns data.count.
  Future<int> getMatchesCount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.likesMatchesCount,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (!response.isSuccess || response.data == null) return 0;
      final data = response.data!['data'] as Map<String, dynamic>?;
      return data?['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get a single match by id (API: GET likes/matches/:id).
  Future<Match> getMatchById(int matchId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.likesMatchById(matchId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess || response.data == null) throw Exception(response.message);
    final data = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
    return Match.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get all matches (from likes/matches)
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

  /// Get matches from matching/matches (API: GET matching/matches). Same shape as likes/matches.
  Future<List<Match>> getMatchingMatches() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.matchingMatches);
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

