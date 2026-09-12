import 'package:flutter/foundation.dart';

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
        return DislikeResponse.fromJson(data);
      }
      return DislikeResponse();
    } catch (e) {
      rethrow;
    }
  }

  /// Superlike a user
  Future<LikeResponse> superlikeUser(int likedUserId, {String? message}) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesSuperlike,
        data: LikeActionRequest(likedUserId: likedUserId, message: message).toJson(),
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
      final data = response.data!;
      final nested = data['data'];
      if (nested is Map) {
        return _parseCount(nested['count']);
      }
      return _parseCount(data['count']);
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
    final data = response.data!;
    final nestedData = data['data'];
    if (nestedData is Map && nestedData['match'] is Map) {
      return Match.fromJson(Map<String, dynamic>.from(nestedData['match'] as Map));
    }
    if (data['match'] is Map) {
      return Match.fromJson(Map<String, dynamic>.from(data['match'] as Map));
    }
    if (nestedData is Map) {
      return Match.fromJson(Map<String, dynamic>.from(nestedData));
    }
    return Match.fromJson(Map<String, dynamic>.from(data));
  }

  /// Get all matches (from likes/matches)
  Future<List<Match>> getMatches() async {
    final response = await _apiService.get<dynamic>(
      ApiEndpoints.likesMatches,
    );
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return parseCollection(response.data, collectionKeys: const ['matches'])
        .map(Match.fromJson)
        .toList();
  }

  /// Get matches from matching/matches (API: GET matching/matches). Same shape as likes/matches.
  Future<List<Match>> getMatchingMatches() async {
    final response = await _apiService.get<dynamic>(ApiEndpoints.matchingMatches);
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return parseCollection(response.data, collectionKeys: const ['matches'])
        .map(Match.fromJson)
        .toList();
  }

  /// Get pending likes (likes received from others)
  Future<List<Like>> getPendingLikes() async {
    final response = await _apiService.get<dynamic>(
      ApiEndpoints.likesPending,
    );
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return parseCollection(
      response.data,
      collectionKeys: const ['pending_likes', 'likes'],
    ).map(Like.fromJson).toList();
  }

  /// Get superlike history
  Future<List<Like>> getSuperlikeHistory() async {
    final response = await _apiService.get<dynamic>(
      ApiEndpoints.likesSuperlikeHistory,
    );
    if (!response.isSuccess) {
      throw Exception(response.message);
    }
    return parseCollection(
      response.data,
      collectionKeys: const ['usage_history', 'superlikes', 'likes'],
    ).map(Like.fromJson).toList();
  }

  /// Backend envelopes vary: `{matches:[...]}`, `{data:{matches:[...]}}`, or a raw list.
  @visibleForTesting
  static List<Map<String, dynamic>> parseCollection(
    dynamic payload, {
    List<String> collectionKeys = const ['matches'],
  }) {
    return _listFromPayload(payload, collectionKeys: collectionKeys)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<dynamic> _listFromPayload(
    dynamic payload, {
    required List<String> collectionKeys,
  }) {
    if (payload == null) return const [];
    if (payload is List) return payload;
    if (payload is! Map) return const [];

    final map = Map<String, dynamic>.from(payload);
    for (final key in collectionKeys) {
      final value = map[key];
      if (value is List) return value;
    }

    final nested = map['data'];
    if (nested is List) return nested;
    if (nested is Map) {
      return _listFromPayload(nested, collectionKeys: collectionKeys);
    }

    return const [];
  }

  static int _parseCount(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

