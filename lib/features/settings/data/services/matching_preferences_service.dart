import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/matching_preferences.dart';

/// Service for GET/PUT matching/discovery preferences (age range, distance, visibility)
class MatchingPreferencesService {
  final ApiService _apiService;

  MatchingPreferencesService(this._apiService);

  /// GET /api/preferences/matching
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

  /// PUT /api/preferences/matching
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
}
