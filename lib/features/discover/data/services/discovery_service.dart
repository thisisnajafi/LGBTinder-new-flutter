import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../../../../shared/services/cache_service.dart';
import '../../../payments/data/services/plan_limits_service.dart';
import '../models/discovery_profile.dart';
import '../models/discovery_filters.dart';
import '../../../matching/data/models/compatibility_score.dart';

/// Discovery service for finding nearby users and matches
class DiscoveryService {
  final ApiService _apiService;
  final CacheService _cacheService;
  final PlanLimitsService _planLimitsService;

  DiscoveryService(
    this._apiService,
    this._cacheService,
    this._planLimitsService,
  );

  /// Get nearby suggestions (cache-first; plan limits applied to cached and API results)
  Future<List<DiscoveryProfile>> getNearbySuggestions({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    final pageNum = page ?? 1;
    final limitNum = limit ?? 20;
    List<DiscoveryProfile>? fromCache;

    int? cap;
    try {
      final limits = await _planLimitsService.getPlanLimits();
      final remaining = limits.usage.swipes.remaining;
      final isUnlimited = limits.usage.swipes.isUnlimited;
      cap = isUnlimited ? null : (remaining > 0 ? remaining : null);
      // When remaining is 0 we still fetch and show suggestions; limit is enforced when user tries to like
    } catch (_) {
      // Plan limits API failed (e.g. 403, missing endpoint) — don't block discover; treat as unlimited
      cap = null;
    }
    try {

      final cacheKey = CacheKeys.nearbySuggestions(pageNum, limitNum);

      final cachedPayload = await _cacheService.getCached<Map<String, dynamic>>(
        cacheKey,
        (json) => Map<String, dynamic>.from(json),
        customExpiry: CacheDuration.matches,
      );
      if (cachedPayload != null) {
        fromCache = _parseNearbySuggestionsResponse(cachedPayload);
        fromCache = _applyLimit(fromCache, cap);
      }

      final queryParams = <String, dynamic>{};
      queryParams['page'] = pageNum;
      queryParams['limit'] = limitNum;
      if (filters != null) {
        if (filters['ageRange'] != null) {
          final ageRange = filters['ageRange'] as RangeValues;
          queryParams['min_age'] = ageRange.start.toInt();
          queryParams['max_age'] = ageRange.end.toInt();
        }
        if (filters['maxDistance'] != null) {
          queryParams['max_distance'] = filters['maxDistance'];
        }
        if (filters['genders'] != null) {
          final genders = filters['genders'] as List<String>;
          if (!genders.contains('All')) {
            queryParams['gender_ids'] = genders.join(',');
          }
        }
        if (filters['verifiedOnly'] == true) queryParams['verified_only'] = '1';
        if (filters['onlineOnly'] == true) queryParams['online_only'] = '1';
        if (filters['premiumOnly'] == true) queryParams['premium_only'] = '1';
      }

      // Always hit the API (no ApiService-level cache) so discover/refresh always calls nearby-suggestions
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.matchingNearbySuggestions,
        queryParameters: queryParams,
        useCache: false,
      );

      final payload = response.data;
      if (payload != null && payload is Map<String, dynamic>) {
        await _cacheService.cacheData(
          cacheKey,
          Map<String, dynamic>.from(payload),
          duration: CacheDuration.matches,
        );
      }
      final list = _parseNearbySuggestionsResponse(response.data);
      return _applyLimit(list, cap);
    } catch (e) {
      if (fromCache != null) return fromCache;
      rethrow;
    }
  }

  /// Cap list to remaining swipes when not unlimited
  static List<DiscoveryProfile> _applyLimit(
    List<DiscoveryProfile> list,
    int? cap,
  ) {
    if (cap == null || list.length <= cap) return list;
    return list.sublist(0, cap);
  }

  /// Fetch nearby suggestions from API only (no cache read). Used by discover cache to merge into feed.
  Future<List<DiscoveryProfile>> fetchNearbySuggestionsFromApi({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    int? cap;
    try {
      final limits = await _planLimitsService.getPlanLimits();
      final remaining = limits.usage.swipes.remaining;
      final isUnlimited = limits.usage.swipes.isUnlimited;
      cap = isUnlimited ? null : (remaining > 0 ? remaining : null);
    } catch (_) {
      cap = null;
    }
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (filters != null) {
      if (filters['ageRange'] != null) {
        final ageRange = filters['ageRange'] as RangeValues;
        queryParams['min_age'] = ageRange.start.toInt();
        queryParams['max_age'] = ageRange.end.toInt();
      }
      if (filters['maxDistance'] != null) {
        queryParams['max_distance'] = filters['maxDistance'];
      }
      if (filters['genders'] != null) {
        final genders = filters['genders'] as List<String>;
        if (!genders.contains('All')) {
          queryParams['gender_ids'] = genders.join(',');
        }
      }
      if (filters['verifiedOnly'] == true) queryParams['verified_only'] = '1';
      if (filters['onlineOnly'] == true) queryParams['online_only'] = '1';
      if (filters['premiumOnly'] == true) queryParams['premium_only'] = '1';
    }
    final response = await _apiService.get<dynamic>(
      ApiEndpoints.matchingNearbySuggestions,
      queryParameters: queryParams,
      useCache: false,
    );
    final list = _parseNearbySuggestionsResponse(response.data);
    return _applyLimit(list, cap);
  }

  /// Get advanced matches with filters
  Future<List<DiscoveryProfile>> getAdvancedMatches({
    Map<String, dynamic>? filters,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (filters != null) queryParams.addAll(filters);

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.matchingAdvanced,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
        return dataList
            .map((item) => DiscoveryProfile.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get compatibility score for a user
  Future<CompatibilityScore> getCompatibilityScore(int userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.matchingCompatibilityScore,
        queryParameters: {'user_id': userId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return CompatibilityScore.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get AI match suggestions
  Future<List<DiscoveryProfile>> getAiSuggestions({
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.matchingAiSuggestions,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
        return dataList
            .map((item) => DiscoveryProfile.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get discovery profiles (main discovery endpoint)
  Future<List<DiscoveryProfile>> getDiscoveryProfiles({
    int limit = 20,
    DiscoveryFilters? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};

      if (filters != null && !filters.isEmpty) {
        queryParams.addAll(filters.toJson());
      }

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.matchingNearbySuggestions,
        queryParameters: queryParams,
      );

      return _parseNearbySuggestionsResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Apply filters to discovery
  Future<List<DiscoveryProfile>> applyFilters(DiscoveryFilters filters) async {
    try {
      final queryParams = filters.toJson();

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.matchingAdvanced,
        queryParameters: queryParams,
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
        return dataList
            .map((item) => DiscoveryProfile.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Like a profile
  /// FIXED: Changed 'user_id' to 'target_user_id' to match backend LikeController
  Future<void> likeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesLike,
        data: {'target_user_id': profileId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Dislike a profile
  /// FIXED: Changed 'user_id' to 'target_user_id' to match backend LikeController
  Future<void> dislikeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesDislike,
        data: {'target_user_id': profileId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Superlike a profile
  /// FIXED: Changed 'user_id' to 'target_user_id' to match backend LikeController
  Future<void> superlikeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesSuperlike,
        data: {'target_user_id': profileId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile for discovery
  Future<DiscoveryProfile> getUserProfile(int userId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.profileById(userId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Convert UserProfile to DiscoveryProfile
        final userProfile = response.data!;
        return DiscoveryProfile(
          id: userProfile['id'] as int,
          firstName: userProfile['first_name'] as String,
          lastName: userProfile['last_name'] as String?,
          age: userProfile['age'] as int?,
          city: userProfile['city'] as String?,
          country: userProfile['country'] as String?,
          gender: userProfile['gender'] as String?,
          profileBio: userProfile['profile_bio'] as String?,
          height: userProfile['height'] as int?,
          imageUrls: userProfile['images'] != null
              ? (userProfile['images'] as List).map((img) => img['image_url'] as String).toList()
              : null,
          primaryImageUrl: userProfile['primary_image_url'] as String?,
          distance: userProfile['distance'] != null ? (userProfile['distance'] as num).toDouble() : null,
          compatibilityScore: userProfile['compatibility_score'] as int?,
          isSuperliked: userProfile['is_superliked'] as bool?,
          lastActive: userProfile['last_active'] != null
              ? DateTime.parse(userProfile['last_active'] as String)
              : null,
        );
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Parses response from GET matching/nearby-suggestions.
  /// Handles both shapes: { suggestions: [...] } or { status, data: { suggestions: [...] } }.
  /// Each suggestion has { user: {...}, match_score, liked_me, suggestion_reasons, matching_criteria }.
  static List<DiscoveryProfile> _parseNearbySuggestionsResponse(dynamic responseData) {
    if (responseData == null) return [];

    Map<String, dynamic>? payload;
    if (responseData is Map<String, dynamic>) {
      final map = responseData;
      if (map['data'] is Map<String, dynamic>) {
        payload = map['data'] as Map<String, dynamic>;
      } else {
        payload = map;
      }
    }

    if (payload == null) return [];

    final suggestions = payload['suggestions'];
    if (suggestions == null || suggestions is! List) {
      final dataList = payload['data'];
      if (dataList is List) {
        return dataList
            .map((item) => DiscoveryProfile.fromJson(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    }

    return (suggestions as List)
        .map((item) {
          final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
          final user = map['user'];
          if (user == null || user is! Map<String, dynamic>) return null;
          return DiscoveryProfile.fromJson(user as Map<String, dynamic>);
        })
        .whereType<DiscoveryProfile>()
        .toList();
  }
}

