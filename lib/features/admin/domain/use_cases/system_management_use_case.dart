import '../../data/repositories/admin_repository.dart';
import '../../data/models/system_health.dart';

/// Use Case: SystemManagementUseCase
/// Handles system administration operations
class SystemManagementUseCase {
  final AdminRepository _adminRepository;

  SystemManagementUseCase(this._adminRepository);

  /// Get system health status
  Future<SystemHealth> getSystemHealth() async {
    try {
      return await _adminRepository.getSystemHealth();
    } catch (e) {
      rethrow;
    }
  }

  /// Clear system cache
  Future<void> clearSystemCache() async {
    try {
      await _adminRepository.clearSystemCache();
    } catch (e) {
      rethrow;
    }
  }

  /// Send system notification
  Future<void> sendSystemNotification(SystemNotificationRequest request) async {
    try {
      // Validate request
      if (request.title.isEmpty || request.message.isEmpty) {
        throw Exception('Title and message are required');
      }

      if (!['info', 'warning', 'error', 'maintenance'].contains(request.type)) {
        throw Exception('Invalid notification type');
      }

      await _adminRepository.sendSystemNotification(request);
    } catch (e) {
      rethrow;
    }
  }

  /// Get app configuration
  Future<AppConfiguration> getAppConfiguration() async {
    try {
      return await _adminRepository.getAppConfiguration();
    } catch (e) {
      rethrow;
    }
  }

  /// Update app configuration
  Future<AppConfiguration> updateAppConfiguration(UpdateAppConfigurationRequest request) async {
    try {
      await _adminRepository.updateAppConfiguration(request);
    } catch (e) {
      rethrow;
    }
  }

  /// Update feature flag
  Future<AppConfiguration> updateFeatureFlag(String featureKey, bool enabled) async {
    try {
      final request = UpdateAppConfigurationRequest(
        features: {featureKey: enabled},
      );
      return await _adminRepository.updateAppConfiguration(request);
    } catch (e) {
      rethrow;
    }
  }

  /// Update app setting
  Future<AppConfiguration> updateAppSetting(String settingKey, dynamic value) async {
    try {
      final request = UpdateAppConfigurationRequest(
        settings: {settingKey: value},
      );
      return await _adminRepository.updateAppConfiguration(request);
    } catch (e) {
      rethrow;
    }
  }

  /// Update app limit
  Future<AppConfiguration> updateAppLimit(String limitKey, int value) async {
    try {
      final request = UpdateAppConfigurationRequest(
        limits: {limitKey: value},
      );
      return await _adminRepository.updateAppConfiguration(request);
    } catch (e) {
      rethrow;
    }
  }
}
