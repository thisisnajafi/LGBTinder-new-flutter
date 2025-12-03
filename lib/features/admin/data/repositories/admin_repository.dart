import '../services/admin_service.dart';
import '../models/admin_user.dart';
import '../models/admin_analytics.dart';

/// Admin repository - wraps AdminService for use in use cases
class AdminRepository {
  final AdminService _adminService;

  AdminRepository(this._adminService);

  /// Get all admin users
  Future<List<AdminUser>> getAdminUsers({
    int? page,
    int? limit,
    String? role,
    bool? isActive,
  }) async {
    return await _adminService.getAdminUsers(
      page: page,
      limit: limit,
      role: role,
      isActive: isActive,
    );
  }

  /// Get admin user by ID
  Future<AdminUser> getAdminUser(int id) async {
    return await _adminService.getAdminUser(id);
  }

  /// Create admin user
  Future<AdminUser> createAdminUser(CreateAdminUserRequest request) async {
    return await _adminService.createAdminUser(request);
  }

  /// Update admin user
  Future<AdminUser> updateAdminUser(UpdateAdminUserRequest request) async {
    return await _adminService.updateAdminUser(request);
  }

  /// Delete admin user
  Future<void> deleteAdminUser(int id) async {
    return await _adminService.deleteAdminUser(id);
  }

  /// Get admin analytics
  Future<AdminAnalytics> getAdminAnalytics({
    AnalyticsFilter? filter,
  }) async {
    return await _adminService.getAdminAnalytics(filter: filter);
  }

  /// Export analytics data
  Future<String> exportAnalytics(ExportAnalyticsRequest request) async {
    return await _adminService.exportAnalytics(request);
  }

  /// Get system health status
  Future<SystemHealth> getSystemHealth() async {
    return await _adminService.getSystemHealth();
  }

  /// Clear system cache
  Future<void> clearSystemCache() async {
    return await _adminService.clearSystemCache();
  }

  /// Send system notification
  Future<void> sendSystemNotification(SystemNotificationRequest request) async {
    return await _adminService.sendSystemNotification(request);
  }

  /// Get app configuration
  Future<AppConfiguration> getAppConfiguration() async {
    return await _adminService.getAppConfiguration();
  }

  /// Update app configuration
  Future<AppConfiguration> updateAppConfiguration(UpdateAppConfigurationRequest request) async {
    return await _adminService.updateAppConfiguration(request);
  }
}
