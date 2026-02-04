import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/settings_summary.dart';
import '../models/user_settings.dart';

/// Service for settings overview (GET /user/settings or summary endpoint).
/// Builds SettingsSummary from user settings when no dedicated summary endpoint exists.
class SettingsSummaryService {
  final ApiService _apiService;

  SettingsSummaryService(this._apiService);

  /// Get settings summary for the overview screen.
  /// Uses user settings and maps to SettingsSummary; can be extended with a dedicated endpoint.
  Future<SettingsSummary> getSummary() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.userSettings,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final settings = UserSettings.fromJson(data);
        final profileMap = data['profile'] is Map
            ? Map<String, dynamic>.from(data['profile'] as Map)
            : (data['first_name'] != null || data['display_name'] != null
                ? {
                    'display_name': data['display_name'] ?? data['first_name'],
                    'first_name': data['first_name'],
                    'last_name': data['last_name'],
                  }
                : null);
        final accountMap = data['account'] is Map
            ? Map<String, dynamic>.from(data['account'] as Map)
            : (data['email'] != null ? {'email': data['email']} : null);
        return SettingsSummary(
          hasProfile: true,
          profileComplete: (settings.discoveryPreferences['profile_complete'] == true) ||
              (data['profile_complete'] == true),
          unreadNotifications: 0,
          twoFactorEnabled: settings.twoFactorEnabled,
          discoveryVisibility: settings.discoveryPreferences['discovery_visibility']?.toString(),
          profile: SettingsSummaryProfile.fromJson(profileMap),
          account: SettingsSummaryAccount.fromJson(accountMap),
          notifications: const SettingsSummaryNotifications(),
        );
      }
    } catch (_) {
      // Fallback when endpoint fails or returns unexpected shape
    }
    return const SettingsSummary();
  }
}
