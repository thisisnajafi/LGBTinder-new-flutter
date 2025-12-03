import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/admin_user.dart';
import '../models/admin_analytics.dart';
import '../models/system_health.dart';

/// Admin service for administrative operations
class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  /// Get all admin users
  Future<List<AdminUser>> getAdminUsers({
    int? page,
    int? limit,
    String? role,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (role != null) queryParams['role'] = role;
      if (isActive != null) queryParams['is_active'] = isActive;

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.adminUsers,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
            .map((item) => AdminUser.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get admin user by ID
  Future<AdminUser> getAdminUser(int id) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.adminUserById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return AdminUser.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create admin user
  Future<AdminUser> createAdminUser(CreateAdminUserRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.adminUsers,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return AdminUser.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update admin user
  Future<AdminUser> updateAdminUser(UpdateAdminUserRequest request) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.adminUserById(request.id),
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return AdminUser.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete admin user
  Future<void> deleteAdminUser(int id) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.adminUserById(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get admin analytics
  Future<AdminAnalytics> getAdminAnalytics({
    AnalyticsFilter? filter,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.adminAnalytics,
        queryParameters: filter?.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return AdminAnalytics.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Export analytics data
  Future<String> exportAnalytics(ExportAnalyticsRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.adminAnalyticsExport,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['download_url'] as String? ?? '';
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get system health status
  Future<SystemHealth> getSystemHealth() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.adminSystemHealth,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return SystemHealth.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear system cache
  Future<void> clearSystemCache() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.adminSystemCacheClear,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send system notification
  Future<void> sendSystemNotification(SystemNotificationRequest request) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.adminSystemNotification,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get app configuration
  Future<AppConfiguration> getAppConfiguration() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.adminAppConfiguration,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return AppConfiguration.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update app configuration
  Future<AppConfiguration> updateAppConfiguration(UpdateAppConfigurationRequest request) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.adminAppConfiguration,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return AppConfiguration.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }
}
