import '../../domain/services/notification_service.dart';
import '../models/notification.dart';
import '../models/notification_preferences.dart';

/// Notification repository - wraps NotificationService for use in use cases
class NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepository(this._notificationService);

  /// Get all notifications for current user
  Future<List<Notification>> getNotifications({
    int? page,
    int? limit,
    String? type,
  }) async {
    return await _notificationService.getNotifications(
      page: page,
      limit: limit,
      type: type,
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    return await _notificationService.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    return await _notificationService.markAllAsRead();
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    return await _notificationService.deleteNotification(notificationId);
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    return await _notificationService.getPreferences();
  }

  /// Update notification preferences
  Future<NotificationPreferences> updatePreferences(
    UpdateNotificationPreferencesRequest request,
  ) async {
    return await _notificationService.updatePreferences(request);
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    return await _notificationService.getUnreadCount();
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    return await _notificationService.sendTestNotification();
  }

  /// Register device for push notifications
  Future<void> registerDevice(String deviceToken, String platform) async {
    return await _notificationService.registerDevice(deviceToken, platform);
  }

  /// Unregister device from push notifications
  Future<void> unregisterDevice(String deviceToken) async {
    return await _notificationService.unregisterDevice(deviceToken);
  }
}
