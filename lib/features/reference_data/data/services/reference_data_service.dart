import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/reference_item.dart';

/// Service for fetching reference data (countries, cities, genders, etc.)
class ReferenceDataService {
  final ApiService _apiService;

  ReferenceDataService(this._apiService);

  /// Get all countries
  Future<List<ReferenceItem>> getCountries() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.countries);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get cities by country ID
  Future<List<ReferenceItem>> getCitiesByCountry(int countryId) async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.citiesByCountry(countryId),
      );
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to extract list from response
  List<ReferenceItem> _extractListFromResponse(dynamic responseData) {
    List<dynamic>? dataList;
    if (responseData is Map<String, dynamic>) {
      if (responseData['data'] != null && responseData['data'] is List) {
        dataList = responseData['data'] as List;
      } else if (responseData['status'] == 'success' && responseData['data'] is List) {
        dataList = responseData['data'] as List;
      }
    } else if (responseData is List) {
      dataList = responseData;
    }

    if (dataList != null) {
      return dataList
          .map((item) => ReferenceItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get all genders
  Future<List<ReferenceItem>> getGenders() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.genders);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all jobs
  Future<List<ReferenceItem>> getJobs() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.jobs);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all education levels
  Future<List<ReferenceItem>> getEducationLevels() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.education);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all interests
  Future<List<ReferenceItem>> getInterests() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.interests);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all languages
  Future<List<ReferenceItem>> getLanguages() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.languages);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all music genres
  Future<List<ReferenceItem>> getMusicGenres() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.musicGenres);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all relationship goals
  Future<List<ReferenceItem>> getRelationshipGoals() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.relationGoals);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all preferred genders
  Future<List<ReferenceItem>> getPreferredGenders() async {
    try {
      final response = await _apiService.get<dynamic>(ApiEndpoints.preferredGenders);
      return _extractListFromResponse(response.data);
    } catch (e) {
      rethrow;
    }
  }
}

