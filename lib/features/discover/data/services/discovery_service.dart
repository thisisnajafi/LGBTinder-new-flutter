import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/discovery_profile.dart';
import '../../../matching/data/models/compatibility_score.dart';

/// Discovery service for finding nearby users and matches
class DiscoveryService {
  final ApiService _apiService;

  DiscoveryService(this._apiService);

  /// Get nearby suggestions
  Future<List<DiscoveryProfile>> getNearbySuggestions({
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

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
}

