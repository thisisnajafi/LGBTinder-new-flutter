import '../../core/constants/api_endpoints.dart';
import 'api_service.dart';

/// OneSignal API (player ID, notification info, preferences, delivery status).
class OneSignalApiService {
  final ApiService _apiService;

  OneSignalApiService(this._apiService);

  /// POST onesignal/update-player-id. Body: player_id.
  Future<Map<String, dynamic>> updatePlayerId(String playerId) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.onesignalUpdatePlayerId,
      data: {'player_id': playerId},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST onesignal/remove-player-id
  Future<Map<String, dynamic>> removePlayerId() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.onesignalRemovePlayerId,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET onesignal/notification-info
  Future<Map<String, dynamic>> getNotificationInfo() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.onesignalNotificationInfo,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST onesignal/update-preferences. Body: optional preferences map.
  Future<Map<String, dynamic>> updatePreferences([Map<String, dynamic>? body]) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.onesignalUpdatePreferences,
      data: body ?? {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// POST onesignal/reset-preferences
  Future<Map<String, dynamic>> resetPreferences() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.onesignalResetPreferences,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }

  /// GET onesignal/delivery-status. Returns delivery_stats, recent_notifications.
  Future<Map<String, dynamic>> getDeliveryStatus() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.onesignalDeliveryStatus,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
    return response.data ?? {};
  }
}
