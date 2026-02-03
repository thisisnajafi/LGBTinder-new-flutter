import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/settings_summary.dart';

/// Service for GET settings summary (overview screen)
class SettingsSummaryService {
  final ApiService _apiService;

  SettingsSummaryService(this._apiService);

  /// GET /api/settings or /api/user/settings — returns summary
  Future<SettingsSummary> getSummary() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.settingsSummary,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (response.isSuccess && response.data != null) {
      return SettingsSummary.fromJson(response.data!);
    }
    throw Exception(response.message);
  }
}
