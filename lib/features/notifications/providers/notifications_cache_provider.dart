import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_providers.dart';
import '../../../core/services/app_logger.dart';
import '../../../shared/models/api_error.dart';
import '../../../shared/services/cache_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/notification.dart' as app_models;
import '../data/services/notification_service.dart';
import 'notification_providers.dart';

/// Cached notifications list with pagination metadata.
class NotificationsCacheState {
  const NotificationsCacheState({
    this.notifications = const [],
    this.initialLoadComplete = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.hasError = false,
    this.errorMessage,
  });

  final List<app_models.Notification> notifications;
  final bool initialLoadComplete;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final bool hasError;
  final String? errorMessage;

  bool get showSkeleton => !initialLoadComplete && notifications.isEmpty;
  bool get showError => hasError && notifications.isEmpty;

  NotificationsCacheState copyWith({
    List<app_models.Notification>? notifications,
    bool? initialLoadComplete,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    bool? hasError,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsCacheState(
      notifications: notifications ?? this.notifications,
      initialLoadComplete: initialLoadComplete ?? this.initialLoadComplete,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      hasError: clearError ? false : (hasError ?? this.hasError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

const int kNotificationsPageSize = 20;

/// Cache-first notifications feed with infinite scroll pagination.
final notificationsCacheProvider =
    StateNotifierProvider<NotificationsCacheNotifier, NotificationsCacheState>(
  (ref) {
    return NotificationsCacheNotifier(
      ref,
      ref.read(notificationServiceProvider),
      ref.read(cacheServiceProvider),
    );
  },
);

class NotificationsCacheNotifier extends StateNotifier<NotificationsCacheState> {
  NotificationsCacheNotifier(
    this._ref,
    this._notificationService,
    this._cacheService,
  ) : super(const NotificationsCacheState()) {
    _init();
  }

  final Ref _ref;
  final NotificationService _notificationService;
  final CacheService _cacheService;

  bool _fetchInProgress = false;

  static const Duration _listCacheDuration = Duration(hours: 24);

  void _init() {
    Future.microtask(() async {
      await loadFromCache();
      await refresh();
    });
  }

  int? get _userId => _ref.read(authProvider).user?.id;

  String? _cacheKey() {
    final userId = _userId;
    if (userId == null || userId <= 0) return null;
    return CacheKeys.userNotifications(userId);
  }

  Future<void> loadFromCache() async {
    final key = _cacheKey();
    if (key == null) return;

    try {
      final cached = await _cacheService.getCached<Map<String, dynamic>>(
        key,
        (json) => Map<String, dynamic>.from(json),
        customExpiry: _listCacheDuration,
      );
      if (cached == null) return;

      final rawList = cached['notifications'];
      if (rawList is! List || rawList.isEmpty) return;

      final notifications = <app_models.Notification>[];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          try {
            notifications.add(app_models.Notification.fromJson(item));
          } catch (_) {}
        }
      }
      if (notifications.isEmpty) return;

      final currentPage = cached['current_page'] is int
          ? cached['current_page'] as int
          : 2;
      final hasMore = cached['has_more'] is bool
          ? cached['has_more'] as bool
          : notifications.length >= kNotificationsPageSize;

      state = state.copyWith(
        notifications: notifications,
        currentPage: currentPage,
        hasMore: hasMore,
        initialLoadComplete: true,
        clearError: true,
      );
      AppLogger.debug(
        'Loaded ${notifications.length} notifications from cache',
        tag: 'NotificationsCache',
      );
    } catch (e, stack) {
      AppLogger.warning(
        'Failed to load notifications cache',
        tag: 'NotificationsCache',
        error: e,
      );
      AppLogger.debug('$stack', tag: 'NotificationsCache');
    }
  }

  Future<void> _persistCache() async {
    final key = _cacheKey();
    if (key == null || state.notifications.isEmpty) return;

    await _cacheService.cacheData(
      key,
      {
        'notifications':
            state.notifications.map((n) => n.toJson()).toList(growable: false),
        'current_page': state.currentPage,
        'has_more': state.hasMore,
      },
      duration: _listCacheDuration,
    );
  }

  Future<void> refresh() async {
    if (_fetchInProgress) return;
    _fetchInProgress = true;

    state = state.copyWith(
      isRefreshing: state.notifications.isNotEmpty,
      clearError: true,
    );

    try {
      final page = await _fetchPage(1);
      if (page == null) return;

      final hasMore = page.length >= kNotificationsPageSize;
      state = state.copyWith(
        notifications: page,
        currentPage: hasMore ? 2 : 1,
        hasMore: hasMore,
        initialLoadComplete: true,
        isRefreshing: false,
        clearError: true,
      );
      unawaited(_persistCache());
    } on ApiError catch (e) {
      state = state.copyWith(
        hasError: state.notifications.isEmpty,
        errorMessage: e.message,
        initialLoadComplete: state.notifications.isNotEmpty,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        hasError: state.notifications.isEmpty,
        errorMessage: e.toString(),
        initialLoadComplete: state.notifications.isNotEmpty,
        isRefreshing: false,
      );
    } finally {
      _fetchInProgress = false;
    }
  }

  Future<void> loadMore() async {
    if (_fetchInProgress ||
        state.isLoadingMore ||
        !state.hasMore ||
        !state.initialLoadComplete) {
      return;
    }
    _fetchInProgress = true;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final page = await _fetchPage(state.currentPage);
      if (page == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final existingIds = state.notifications.map((e) => e.id).toSet();
      final merged = [
        ...state.notifications,
        ...page.where((n) => !existingIds.contains(n.id)),
      ];
      final hasMore = page.length >= kNotificationsPageSize;

      state = state.copyWith(
        notifications: merged,
        currentPage: hasMore ? state.currentPage + 1 : state.currentPage,
        hasMore: hasMore,
        isLoadingMore: false,
        clearError: true,
      );
      unawaited(_persistCache());
    } on ApiError catch (e) {
      AppLogger.warning(
        'Load more notifications failed',
        tag: 'NotificationsCache',
        error: e,
      );
      state = state.copyWith(isLoadingMore: false);
    } catch (e) {
      AppLogger.warning(
        'Load more notifications failed',
        tag: 'NotificationsCache',
        error: e,
      );
      state = state.copyWith(isLoadingMore: false);
    } finally {
      _fetchInProgress = false;
    }
  }

  Future<List<app_models.Notification>?> _fetchPage(int page) async {
    return _notificationService.getNotifications(
      page: page,
      limit: kNotificationsPageSize,
    );
  }

  void markAsReadLocal(int notificationId) {
    state = state.copyWith(
      notifications: state.notifications
          .map(
            (n) => n.id == notificationId
                ? app_models.Notification(
                    id: n.id,
                    type: n.type,
                    title: n.title,
                    message: n.message,
                    createdAt: n.createdAt,
                    isRead: true,
                    data: n.data,
                    userId: n.userId,
                    userName: n.userName,
                    userImageUrl: n.userImageUrl,
                    actionUrl: n.actionUrl,
                    isPlanRestricted: n.isPlanRestricted,
                    upgradeRequired: n.upgradeRequired,
                  )
                : n,
          )
          .toList(growable: false),
    );
    unawaited(_persistCache());
  }

  void markAllAsReadLocal() {
    state = state.copyWith(
      notifications: state.notifications
          .map(
            (n) => app_models.Notification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              createdAt: n.createdAt,
              isRead: true,
              data: n.data,
              userId: n.userId,
              userName: n.userName,
              userImageUrl: n.userImageUrl,
              actionUrl: n.actionUrl,
              isPlanRestricted: n.isPlanRestricted,
              upgradeRequired: n.upgradeRequired,
            ),
          )
          .toList(growable: false),
    );
    unawaited(_persistCache());
  }

  void removeLocal(int notificationId) {
    state = state.copyWith(
      notifications: state.notifications
          .where((n) => n.id != notificationId)
          .toList(growable: false),
    );
    unawaited(_persistCache());
  }

  void clearAllLocal() {
    state = state.copyWith(
      notifications: const [],
      currentPage: 1,
      hasMore: true,
      initialLoadComplete: true,
      clearError: true,
    );
    final key = _cacheKey();
    if (key != null) {
      unawaited(_cacheService.clearCache(key));
    }
  }
}
