import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/user_settings.dart';
import '../models/privacy_settings.dart';
import '../models/device_session.dart';

/// Settings service for user settings and account management
class SettingsService {
  final ApiService _apiService;

  SettingsService(this._apiService);

  /// Get user settings
  Future<UserSettings> getUserSettings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.userSettings,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserSettings.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update user settings
  Future<UserSettings> updateUserSettings(UpdateSettingsRequest request) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.userSettings,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return UserSettings.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get privacy settings
  Future<PrivacySettings> getPrivacySettings() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.privacySettings,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return PrivacySettings.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update privacy settings
  Future<PrivacySettings> updatePrivacySettings(UpdatePrivacySettingsRequest request) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.privacySettings,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return PrivacySettings.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get device sessions
  Future<List<DeviceSession>> getDeviceSessions() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiEndpoints.deviceSessions,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) => DeviceSession.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Revoke device session
  Future<void> revokeDeviceSession(RevokeSessionRequest request) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.deviceSessionById(request.sessionId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Trust device session
  Future<void> trustDeviceSession(TrustDeviceRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.deviceSessionTrust(request.sessionId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount(String password, String reason) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.deleteAccount,
        data: {
          'password': password,
          'reason': reason,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.exportData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear app cache
  Future<void> clearCache() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.clearCache,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.resetSettings,
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
