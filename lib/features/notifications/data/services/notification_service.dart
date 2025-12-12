import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/notification.dart';
import '../models/notification_preferences.dart';

/// Notification service
class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// Get all notifications
  /// FIXED: Updated to handle backend response structure: {data: {notifications: [...], unread_count: 0}}
  Future<List<Notification>> getNotifications({
    int? page,
    int? limit,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly;

      final response = await _apiService.get<dynamic>(
        ApiEndpoints.notifications,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      List<dynamic>? dataList;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        // Handle nested structure: {data: {notifications: [...]}}
        if (data['data'] != null && data['data'] is Map<String, dynamic>) {
          final dataMap = data['data'] as Map<String, dynamic>;
          if (dataMap['notifications'] != null && dataMap['notifications'] is List) {
            dataList = dataMap['notifications'] as List;
          }
        }
        // Fallback: direct list in data: {data: [...]}
        else if (data['data'] != null && data['data'] is List) {
          dataList = data['data'] as List;
        }
      } else if (response.data is List) {
        dataList = response.data as List;
      }

      if (dataList != null) {
        return dataList
            .map((item) {
              try {
                return Notification.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                // Skip malformed notifications instead of crashing
                return null;
              }
            })
            .whereType<Notification>()
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnreadCount,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['count'] as int? ?? response.data!['unread_count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsRead(notificationId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsReadAll,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.notificationsById(notificationId),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.notificationPreferences,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return NotificationPreferences.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update notification preferences
  Future<NotificationPreferences> updatePreferences(
    UpdateNotificationPreferencesRequest request,
  ) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        ApiEndpoints.notificationPreferences,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        return NotificationPreferences.fromJson(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsTest,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (!response.isSuccess) {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Register device for push notifications
  Future<void> registerDevice(String deviceToken, String platform) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsRegisterDevice,
        data: {
          'device_token': deviceToken,
          'platform': platform,
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

  /// Unregister device from push notifications
  Future<void> unregisterDevice(String deviceToken) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnregisterDevice,
        data: {'device_token': deviceToken},
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

