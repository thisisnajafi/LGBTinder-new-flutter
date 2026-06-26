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

  /// POST sessions/revoke/:id — log out a specific device session.
  Future<void> revokeSession(int sessionId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.sessionRevoke(sessionId),
      data: {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// POST sessions/revoke-all — log out every other device; keeps the current session.
  Future<int> revokeAllOtherSessions() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.sessionsRevokeAll,
      data: {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);

    final data = response.data;
    if (data is Map<String, dynamic> && data['revoked_count'] != null) {
      final count = data['revoked_count'];
      if (count is int) return count;
      return int.tryParse(count.toString()) ?? 0;
    }
    return 0;
  }
}
