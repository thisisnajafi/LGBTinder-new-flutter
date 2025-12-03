import '../../domain/services/settings_service.dart';
import '../models/user_settings.dart';
import '../models/privacy_settings.dart';
import '../models/device_session.dart';

/// Settings repository - wraps SettingsService for use in use cases
class SettingsRepository {
  final SettingsService _settingsService;

  SettingsRepository(this._settingsService);

  /// Get user settings
  Future<UserSettings> getUserSettings() async {
    return await _settingsService.getUserSettings();
  }

  /// Update user settings
  Future<UserSettings> updateUserSettings(UpdateSettingsRequest request) async {
    return await _settingsService.updateUserSettings(request);
  }

  /// Get privacy settings
  Future<PrivacySettings> getPrivacySettings() async {
    return await _settingsService.getPrivacySettings();
  }

  /// Update privacy settings
  Future<PrivacySettings> updatePrivacySettings(UpdatePrivacySettingsRequest request) async {
    return await _settingsService.updatePrivacySettings(request);
  }

  /// Get active device sessions
  Future<List<DeviceSession>> getDeviceSessions() async {
    return await _settingsService.getDeviceSessions();
  }

  /// Revoke device session
  Future<void> revokeDeviceSession(RevokeSessionRequest request) async {
    return await _settingsService.revokeDeviceSession(request);
  }

  /// Trust device session
  Future<void> trustDeviceSession(TrustDeviceRequest request) async {
    return await _settingsService.trustDeviceSession(request);
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    return await _settingsService.changePassword(currentPassword, newPassword);
  }

  /// Delete account
  Future<void> deleteAccount(String password, String reason) async {
    return await _settingsService.deleteAccount(password, reason);
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData() async {
    return await _settingsService.exportUserData();
  }

  /// Clear app cache
  Future<void> clearCache() async {
    return await _settingsService.clearCache();
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    return await _settingsService.resetToDefaults();
  }
}
