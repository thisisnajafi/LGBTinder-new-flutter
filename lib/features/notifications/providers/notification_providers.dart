import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../data/services/notification_service.dart';

/// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationService(apiService);
});

/// Local unread badge count. When set, the nav icon uses this instead of a
/// server fetch so mark-all-read can hide the number as soon as the API lands.
final unreadNotificationCountSeedProvider = StateProvider<int?>((ref) => null);

/// Unread Notification Count Provider
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final seeded = ref.watch(unreadNotificationCountSeedProvider);
  if (seeded != null) return seeded;
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUnreadCount();
});

