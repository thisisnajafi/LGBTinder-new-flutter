import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/matching_preferences.dart';

/// Service for GET/PUT /api/preferences/matching (discovery preferences).
class MatchingPreferencesService {
  final ApiService _apiService;

  MatchingPreferencesService(this._apiService);

  /// Get current matching/discovery preferences.
  Future<MatchingPreferences> getPreferences() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.preferencesMatching,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return MatchingPreferences.fromJson(response.data!);
    }
    throw Exception(response.message);
  }

  /// Update matching/discovery preferences.
  Future<MatchingPreferences> updatePreferences(MatchingPreferences prefs) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.preferencesMatching,
      data: prefs.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return MatchingPreferences.fromJson(response.data!);
    }
    throw Exception(response.message);
  }

  /// Get age preferences (API: GET preferences/age). Returns { min_age, max_age }.
  Future<Map<String, dynamic>> getAgePreferences() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.preferencesAge,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Update age preferences (API: PUT preferences/age). Body: min_age, max_age.
  Future<Map<String, dynamic>> updateAgePreferences({required int minAge, required int maxAge}) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.preferencesAge,
      data: {'min_age': minAge, 'max_age': maxAge},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// Reset age preferences (API: DELETE preferences/age).
  Future<void> resetAgePreferences() async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.preferencesAge,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }
}
