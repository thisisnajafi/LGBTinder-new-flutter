import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/services/api_service.dart';
import '../models/notification.dart';
import '../models/notification_preferences.dart';

/// Notification service
class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// Get notifications page (list + pagination metadata).
  Future<NotificationsPageResult> getNotifications({
    int? page,
    int? limit,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly;

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        useCache: false,
        fromJson: (json) => Map<String, dynamic>.from(json as Map),
      );

      if (!response.isSuccess || response.data == null) {
        return NotificationsPageResult.empty;
      }

      final payload = _unwrapNotificationsPayload(response.data!);
      final rawList = payload['notifications'];
      final notifications = <Notification>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              notifications.add(Notification.fromJson(item));
            } catch (_) {}
          } else if (item is Map) {
            try {
              notifications.add(
                Notification.fromJson(Map<String, dynamic>.from(item)),
              );
            } catch (_) {}
          }
        }
      }

      final pagination = payload['pagination'];
      final hasMore = pagination is Map
          ? pagination['has_more'] == true
          : notifications.length >= (limit ?? 20);

      final unreadRaw = payload['unread_count'];
      final unreadCount = unreadRaw is int
          ? unreadRaw
          : int.tryParse(unreadRaw?.toString() ?? '') ?? 0;

      return NotificationsPageResult(
        notifications: notifications,
        hasMore: hasMore,
        unreadCount: unreadCount,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _unwrapNotificationsPayload(Map<String, dynamic> data) {
    if (data['notifications'] is List) return data;
    final nested = data['data'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return data;
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnreadCount,
        useCache: false,
        fromJson: (json) => Map<String, dynamic>.from(json as Map),
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return data['count'] as int? ??
            data['unread_count'] as int? ??
            int.tryParse(data['unread_count']?.toString() ?? '') ??
            0;
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

  /// Delete a notification (DELETE notifications/:id)
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

  /// Delete all notifications (API: DELETE /notifications).
  Future<void> deleteAllNotifications() async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (!response.isSuccess) throw Exception(response.message);
  }

  /// Get notification permissions (API: GET notifications/permissions).
  /// Returns data with permissions, available_types, can_customize, can_set_quiet_hours.
  Future<Map<String, dynamic>> getPermissions() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsPermissions,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.isSuccess && response.data != null) {
        return response.data!;
      }
    } catch (e) {
      rethrow;
    }
    return {};
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

