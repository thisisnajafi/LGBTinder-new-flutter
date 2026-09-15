import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_providers.dart';
import '../../../core/services/app_logger.dart';
import '../../../features/chat/data/local/chat_database_provider.dart';
import '../../../shared/models/api_error.dart';
import '../../../shared/services/cache_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/local/notifications_local_repository.dart';
import '../data/models/notification.dart' as app_models;
import '../data/services/notification_service.dart';
import 'notification_providers.dart';

export '../data/local/notifications_list_snapshot.dart';

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

final notificationsLocalRepositoryProvider =
    Provider<NotificationsLocalRepository>((ref) {
  return NotificationsLocalRepository(ref.watch(appDatabaseProvider));
});

/// Cache-first notifications feed with infinite scroll pagination.
final notificationsCacheProvider =
    StateNotifierProvider<NotificationsCacheNotifier, NotificationsCacheState>(
  (ref) {
    return NotificationsCacheNotifier(
      ref,
      ref.read(notificationServiceProvider),
      ref.read(cacheServiceProvider),
      ref.read(notificationsLocalRepositoryProvider),
    );
  },
);

class NotificationsCacheNotifier extends StateNotifier<NotificationsCacheState> {
  NotificationsCacheNotifier(
    this._ref,
    this._notificationService,
    this._cacheService,
    this._localRepository,
  ) : super(const NotificationsCacheState()) {
    _init();
  }

  final Ref _ref;
  final NotificationService _notificationService;
  final CacheService _cacheService;
  final NotificationsLocalRepository _localRepository;

  bool _fetchInProgress = false;
  int _badgeEpoch = 0;

  static const Duration _legacyPrefsCacheDuration = Duration(hours: 24);

  void _init() {
    Future.microtask(() async {
      await loadFromCache();
      await refresh();
    });
  }

  int? get _userId => _ref.read(authProvider).user?.id;

  String? _legacyCacheKey() {
    final userId = _userId;
    if (userId == null || userId <= 0) return null;
    return CacheKeys.userNotifications(userId);
  }

  Future<void> loadFromCache() async {
    final userId = _userId;
    if (userId == null || userId <= 0) return;

    try {
      final local = await _localRepository.load(userId);
      if (local != null && local.notifications.isNotEmpty) {
        _applySnapshot(local);
        return;
      }

      final key = _legacyCacheKey();
      if (key == null) return;
      final cached = await _cacheService.getCached<Map<String, dynamic>>(
        key,
        (json) => Map<String, dynamic>.from(json),
        customExpiry: _legacyPrefsCacheDuration,
      );
      if (cached == null) return;

      final snapshot = NotificationsLocalSnapshot.fromCacheMap(cached);
      if (snapshot == null) return;

      _applySnapshot(snapshot);
      unawaited(_persistLocal(unreadCount: snapshot.unreadCount));
      AppLogger.debug(
        'Migrated ${snapshot.notifications.length} notifications from prefs cache',
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

  void _applySnapshot(NotificationsLocalSnapshot snapshot) {
    state = state.copyWith(
      notifications: snapshot.notifications,
      currentPage: snapshot.currentPage,
      hasMore: snapshot.hasMore,
      initialLoadComplete: true,
      clearError: true,
    );
    final unread = snapshot.unreadCount ??
        snapshot.notifications.where((n) => !n.isRead).length;
    _syncUnreadBadge(unread, epoch: _badgeEpoch);
    AppLogger.debug(
      'Loaded ${snapshot.notifications.length} notifications from local cache',
      tag: 'NotificationsCache',
    );
  }

  Future<void> _persistLocal({int? unreadCount}) async {
    final userId = _userId;
    if (userId == null || userId <= 0) return;

    await _localRepository.replace(
      ownerUserId: userId,
      notifications: state.notifications,
      currentPage: state.currentPage,
      hasMore: state.hasMore,
      unreadCount: unreadCount ??
          state.notifications.where((n) => !n.isRead).length,
    );
  }

  Future<void> refresh() async {
    if (_fetchInProgress) return;
    _fetchInProgress = true;

    state = state.copyWith(
      isRefreshing: state.notifications.isNotEmpty,
      clearError: true,
    );

    final epoch = _badgeEpoch;
    try {
      final page = await _fetchPage(1);
      if (page == null) return;

      state = state.copyWith(
        notifications: withoutChatMessageNotifications(page.notifications),
        currentPage: page.hasMore ? 2 : 1,
        hasMore: page.hasMore,
        initialLoadComplete: true,
        isRefreshing: false,
        clearError: true,
      );
      _syncUnreadBadge(page.unreadCount, epoch: epoch);
      unawaited(_persistLocal(unreadCount: page.unreadCount));
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
    final epoch = _badgeEpoch;

    try {
      final page = await _fetchPage(state.currentPage);
      if (page == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final existingIds = state.notifications.map((e) => e.id).toSet();
      final merged = [
        ...state.notifications,
        ...withoutChatMessageNotifications(page.notifications)
            .where((n) => !existingIds.contains(n.id)),
      ];

      state = state.copyWith(
        notifications: merged,
        currentPage: page.hasMore ? state.currentPage + 1 : state.currentPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
        clearError: true,
      );
      _syncUnreadBadge(page.unreadCount, epoch: epoch);
      unawaited(_persistLocal(unreadCount: page.unreadCount));
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

  Future<app_models.NotificationsPageResult?> _fetchPage(int page) async {
    return _notificationService.getNotifications(
      page: page,
      limit: kNotificationsPageSize,
    );
  }

  void _syncUnreadBadge(int unreadCount, {required int epoch}) {
    if (epoch != _badgeEpoch) return;
    _ref.read(unreadNotificationCountSeedProvider.notifier).state = unreadCount;
  }

  void clearUnreadBadge() {
    _badgeEpoch++;
    _ref.read(unreadNotificationCountSeedProvider.notifier).state = 0;
  }

  void syncBadgeFromLocalList() {
    final unread = state.notifications.where((n) => !n.isRead).length;
    _ref.read(unreadNotificationCountSeedProvider.notifier).state = unread;
  }

  void markAsReadLocal(int notificationId) {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(growable: false),
    );
    unawaited(_persistLocal());
  }

  void markAllAsReadLocal() {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList(growable: false),
    );
    unawaited(_persistLocal(unreadCount: 0));
  }

  void removeLocal(int notificationId) {
    state = state.copyWith(
      notifications: state.notifications
          .where((n) => n.id != notificationId)
          .toList(growable: false),
    );
    syncBadgeFromLocalList();
    unawaited(_persistLocal());
  }

  void insertLocal(app_models.Notification notification, {int? index}) {
    if (state.notifications.any((n) => n.id == notification.id)) return;
    final next = [...state.notifications];
    final insertAt = (index ?? 0).clamp(0, next.length);
    next.insert(insertAt, notification);
    state = state.copyWith(notifications: next);
    syncBadgeFromLocalList();
    unawaited(_persistLocal());
  }

  void clearAllLocal() {
    state = state.copyWith(
      notifications: const [],
      currentPage: 1,
      hasMore: true,
      initialLoadComplete: true,
      clearError: true,
    );
    clearUnreadBadge();
    final userId = _userId;
    if (userId != null && userId > 0) {
      unawaited(_localRepository.clear(userId));
    }
    final key = _legacyCacheKey();
    if (key != null) {
      unawaited(_cacheService.clearCache(key));
    }
  }
}
