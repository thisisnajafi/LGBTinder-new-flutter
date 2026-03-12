import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Safety API (guidelines, emergency-alert, share-location, nearby-safe-places, report, report-categories/history, moderate-content, statistics).
class SafetyApiService {
  final ApiService _apiService;

  SafetyApiService(this._apiService);

  /// GET safety/guidelines — meeting & online safety guidelines.
  Future<Map<String, dynamic>> getGuidelines() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.safetyGuidelines,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST safety/emergency-alert. Body: location: { latitude, longitude }, alert_type.
  Future<Map<String, dynamic>> sendEmergencyAlert(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.safetyEmergencyAlert,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST safety/share-location. Body: latitude, longitude, duration_minutes.
  Future<Map<String, dynamic>> shareLocation({
    required double latitude,
    required double longitude,
    required int durationMinutes,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.safetyShareLocation,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'duration_minutes': durationMinutes,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET safety/nearby-safe-places. Query: latitude, longitude.
  Future<Map<String, dynamic>> getNearbySafePlaces({
    required double latitude,
    required double longitude,
  }) async {
    final path =
        '${ApiEndpoints.safetyNearbySafePlaces}?latitude=$latitude&longitude=$longitude';
    final response = await _apiService.get<Map<String, dynamic>>(
      path,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST safety/report. Body: report_type, description; optional reported_user_id, category, etc.
  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.safetyReport,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET safety/report-categories.
  Future<Map<String, dynamic>> getReportCategories() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.safetyReportCategories,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET safety/report-history. Optional [page] for pagination.
  Future<Map<String, dynamic>> getReportHistory({int? page}) async {
    final path = page != null
        ? '${ApiEndpoints.safetyReportHistory}?page=$page'
        : ApiEndpoints.safetyReportHistory;
    final response = await _apiService.get<Map<String, dynamic>>(
      path,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST safety/moderate-content. Body: content_type; optional content_id, action.
  Future<Map<String, dynamic>> moderateContent(Map<String, dynamic> body) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.safetyModerateContent,
      data: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET safety/statistics.
  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.safetyStatistics,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }
}
