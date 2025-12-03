import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/user_info.dart';
import '../models/notification_preferences.dart';

/// User management service
class UserService {
  final ApiService _apiService;

  UserService(this._apiService);

  /// Get current user info
  Future<UserInfo> getUserInfo() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.user,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserInfo.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Save OneSignal player ID
  Future<void> saveOneSignalPlayerId(String playerId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.userOnesignalPlayer,
        data: {'player_id': playerId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(NotificationPreferences preferences) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.userNotificationPreferences,
        data: preferences.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update show adult content setting
  Future<void> updateShowAdultContent(bool showAdultContent) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.userShowAdultContent,
        data: {'show_adult_content': showAdultContent},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}

