import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/sound_preferences.dart';

/// API client for user sound preference endpoints.
class SoundPreferencesService {
  SoundPreferencesService(this._apiService);

  final ApiService _apiService;

  Future<SoundPreferences> getPreferences() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.userSoundPreferences,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return SoundPreferences.fromJson(response.data!);
    }
    throw Exception(response.message);
  }

  Future<SoundPreferences> updatePreferences(SoundPreferences prefs) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      ApiEndpoints.userSoundPreferences,
      data: prefs.toJson(),
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return SoundPreferences.fromJson(response.data!);
    }
    throw Exception(response.message);
  }

  Future<SoundCatalog> getAvailableSounds() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.userAvailableSounds,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      return SoundCatalog.fromJson(response.data!);
    }
    throw Exception(response.message);
  }
}
