import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Landing (public) API data for about screen, contact, etc.
/// Routes 1–8 in API_DOCUMENTATION.md.
class LandingService {
  final ApiService _apiService;

  LandingService(this._apiService);

  /// GET landing/settings — app store URLs, tagline, features, FAQ (no auth).
  Future<LandingSettings?> getSettings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.landingSettings,
        fromJson: (json) => json as Map<String, dynamic>,
        useCache: true,
      );
      if (response.isSuccess && response.data != null) {
        return LandingSettings.fromJson(response.data!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST landing/contact — send contact form (no auth).
  /// Body: name, email, message.
  Future<bool> sendContact({required String name, required String email, required String message}) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.landingContact,
        data: {'name': name, 'email': email, 'message': message},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}

/// Parsed GET landing/settings response (data object).
class LandingSettings {
  final String? appStoreUrl;
  final String? googlePlayUrl;
  final String? siteName;
  final String? tagline;
  final String? description;

  LandingSettings({
    this.appStoreUrl,
    this.googlePlayUrl,
    this.siteName,
    this.tagline,
    this.description,
  });

  factory LandingSettings.fromJson(Map<String, dynamic> json) {
    // ApiResponse passes the unwrapped 'data' object, so json is the inner object
    return LandingSettings(
      appStoreUrl: json['app_store_url']?.toString(),
      googlePlayUrl: json['google_play_url']?.toString(),
      siteName: json['site_name']?.toString(),
      tagline: json['tagline']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
