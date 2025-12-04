import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/discovery_profile.dart';
import '../models/discovery_filters.dart';
import '../../../matching/data/models/compatibility_score.dart';

/// Discovery service for finding nearby users and matches
class DiscoveryService {
  final ApiService _apiService;

  DiscoveryService(this._apiService);

  /// Get nearby suggestions
  Future<List<DiscoveryProfile>> getNearbySuggestions({
    int? page,
    int? limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      // Add filter parameters if provided
      if (filters != null) {
        // Age range
        if (filters['ageRange'] != null) {
          final ageRange = filters['ageRange'] as RangeValues;
          queryParams['min_age'] = ageRange.start.toInt();
          queryParams['max_age'] = ageRange.end.toInt();
        }

        // Max distance
        if (filters['maxDistance'] != null) {
          queryParams['max_distance'] = filters['maxDistance'];
        }

        // Gender filters
        if (filters['genders'] != null) {
          final genders = filters['genders'] as List<String>;
          if (!genders.contains('All')) {
            queryParams['gender_ids'] = genders.join(',');
          }
        }

        // Verification filter
        if (filters['verifiedOnly'] == true) {
          queryParams['verified_only'] = '1';
        }

        // Online status filter
        if (filters['onlineOnly'] == true) {
          queryParams['online_only'] = '1';
        }

        // Premium filter
        if (filters['premiumOnly'] == true) {
          queryParams['premium_only'] = '1';
        }
      }

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.matchingNearbySuggestions,
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
  Future<void> likeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesLike,
        data: {'user_id': profileId},
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
  Future<void> dislikeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesDislike,
        data: {'user_id': profileId},
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
  Future<void> superlikeProfile(int profileId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.likesSuperlike,
        data: {'user_id': profileId},
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
}

