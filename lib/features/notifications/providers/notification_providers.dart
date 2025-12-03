import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/notification_service.dart';

/// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationService(apiService);
});

/// Unread Notification Count Provider
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getUnreadCount();
});

