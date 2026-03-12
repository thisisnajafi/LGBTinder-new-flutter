import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// Sessions API (store, activity, revoke).
class SessionApiService {
  final ApiService _apiService;

  SessionApiService(this._apiService);

  /// POST sessions/store. Body: device_name.
  Future<Map<String, dynamic>> storeSession({String deviceName = 'app'}) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.sessionsStore,
      data: {'device_name': deviceName},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST sessions/activity. Body: session_id (required).
  Future<void> reportActivity(String sessionId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.sessionActivity,
      data: {'session_id': sessionId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// POST sessions/revoke/:id
  Future<void> revokeSession(int sessionId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.sessionRevoke(sessionId),
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }
}
