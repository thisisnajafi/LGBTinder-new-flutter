import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification.dart';
import '../data/models/notification_preferences.dart';
import '../domain/use_cases/get_notifications_use_case.dart';
import '../domain/use_cases/mark_as_read_use_case.dart';
import '../domain/use_cases/delete_notification_use_case.dart';
import '../domain/use_cases/update_preferences_use_case.dart';

/// Notification provider - manages notification state and operations
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final getNotificationsUseCase = ref.watch(getNotificationsUseCaseProvider);
  final markAsReadUseCase = ref.watch(markAsReadUseCaseProvider);
  final deleteNotificationUseCase = ref.watch(deleteNotificationUseCaseProvider);
  final updatePreferencesUseCase = ref.watch(updatePreferencesUseCaseProvider);

  return NotificationNotifier(
    getNotificationsUseCase: getNotificationsUseCase,
    markAsReadUseCase: markAsReadUseCase,
    deleteNotificationUseCase: deleteNotificationUseCase,
    updatePreferencesUseCase: updatePreferencesUseCase,
  );
});

/// Notification state
class NotificationState {
  final List<Notification> notifications;
  final NotificationPreferences? preferences;
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final int unreadCount;
  final bool hasMore;
  final int currentPage;

  NotificationState({
    this.notifications = const [],
    this.preferences,
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.unreadCount = 0,
    this.hasMore = true,
    this.currentPage = 1,
  });

  NotificationState copyWith({
    List<Notification>? notifications,
    NotificationPreferences? preferences,
    bool? isLoading,
    bool? isUpdating,
    String? error,
    int? unreadCount,
    bool? hasMore,
    int? currentPage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error ?? this.error,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  final UpdatePreferencesUseCase _updatePreferencesUseCase;

  NotificationNotifier({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required DeleteNotificationUseCase deleteNotificationUseCase,
    required UpdatePreferencesUseCase updatePreferencesUseCase,
  }) : _getNotificationsUseCase = getNotificationsUseCase,
       _markAsReadUseCase = markAsReadUseCase,
       _deleteNotificationUseCase = deleteNotificationUseCase,
       _updatePreferencesUseCase = updatePreferencesUseCase,
       super(NotificationState());

  /// Load notifications
  Future<void> loadNotifications({bool isRefresh = false, String? type}) async {
    if (state.isLoading && !isRefresh) return;
    if (!state.hasMore && !isRefresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final notifications = await _getNotificationsUseCase.execute(
        page: isRefresh ? 1 : state.currentPage,
        limit: 20,
        type: type,
      );

      state = state.copyWith(
        notifications: isRefresh ? notifications : [...state.notifications, ...notifications],
        isLoading: false,
        hasMore: notifications.length == 20,
        currentPage: isRefresh ? 2 : state.currentPage + 1,
      );

      // Update unread count
      await _updateUnreadCount();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load notification preferences
  Future<void> loadPreferences() async {
    try {
      final preferences = await _updatePreferencesUseCase.getPreferences();
      state = state.copyWith(preferences: preferences);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(UpdateNotificationPreferencesRequest request) async {
    state = state.copyWith(isUpdating: true, error: null);

    try {
      final updatedPreferences = await _updatePreferencesUseCase.execute(request);
      state = state.copyWith(
        preferences: updatedPreferences,
        isUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _markAsReadUseCase.execute(notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return Notification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            createdAt: notification.createdAt,
            isRead: true,
            data: notification.data,
            userId: notification.userId,
            userImageUrl: notification.userImageUrl,
            actionUrl: notification.actionUrl,
          );
        }
        return notification;
      }).toList();

      state = state.copyWith(notifications: updatedNotifications);
      await _updateUnreadCount();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _markAsReadUseCase.markAllAsRead();

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        return Notification(
          id: notification.id,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          createdAt: notification.createdAt,
          isRead: true,
          data: notification.data,
          userId: notification.userId,
          userImageUrl: notification.userImageUrl,
          actionUrl: notification.actionUrl,
        );
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _deleteNotificationUseCase.execute(notificationId);

      // Update local state
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      state = state.copyWith(notifications: updatedNotifications);
      await _updateUnreadCount();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add new notification (for real-time updates)
  void addNotification(Notification notification) {
    final updatedNotifications = [notification, ...state.notifications];
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: state.unreadCount + (notification.isRead ? 0 : 1),
    );
  }

  /// Update unread count
  Future<void> _updateUnreadCount() async {
    try {
      final unreadCount = await _notificationRepository.getUnreadCount();
      state = state.copyWith(unreadCount: unreadCount);
    } catch (e) {
      // Don't set error for unread count updates, just keep current state
    }
  }

  /// Check if notification should be shown based on preferences
  bool shouldShowNotification(String type) {
    if (state.preferences == null) return true;
    return state.preferences!.isNotificationAllowed(type);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset notification state
  void reset() {
    state = NotificationState();
  }
}

// Use case providers
final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((ref) {
  throw UnimplementedError('GetNotificationsUseCase must be overridden in the provider scope');
});

final markAsReadUseCaseProvider = Provider<MarkAsReadUseCase>((ref) {
  throw UnimplementedError('MarkAsReadUseCase must be overridden in the provider scope');
});

final deleteNotificationUseCaseProvider = Provider<DeleteNotificationUseCase>((ref) {
  throw UnimplementedError('DeleteNotificationUseCase must be overridden in the provider scope');
});

final updatePreferencesUseCaseProvider = Provider<UpdatePreferencesUseCase>((ref) {
  throw UnimplementedError('UpdatePreferencesUseCase must be overridden in the provider scope');
});
