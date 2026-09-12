// Screen: NotificationsScreen
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/cache/cache_manager.dart' show notifyNewMatch;
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../core/widgets/app_list_view.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_notifications.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../data/models/notification.dart' as app_models;
import '../../providers/notification_providers.dart';
import '../../providers/notifications_cache_provider.dart';
import '../widgets/notification_tile.dart';
import '../../../../widgets/error_handling/empty_state.dart';
import '../../../../routes/app_router.dart';
import '../../../../widgets/modals/confirmation_dialog.dart';
import '../../../../shared/services/notification_navigation.dart';

/// Notifications screen - Displays all user notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({
    super.key,
    this.selectedTabIndex,
    this.notificationsTabIndex,
  });

  /// When embedded in [HomePage], mark all as read when leaving this tab.
  final int? selectedTabIndex;
  final int? notificationsTabIndex;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _PendingNotificationDelete {
  _PendingNotificationDelete({
    required this.notification,
    required this.index,
    required this.timer,
  });

  final app_models.Notification notification;
  final int index;
  final Timer timer;
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _categoryIndex = 0;
  final Map<int, _PendingNotificationDelete> _pendingDeletes = {};

  static const _categories = [
    'All',
    'Matches',
    'Likes',
    'Views',
    'System',
  ];

  static const _undoWindow = AppAnimations.chatListDeleteUndo;

  bool get _isSelectedTab =>
      widget.selectedTabIndex != null &&
      widget.notificationsTabIndex != null &&
      widget.selectedTabIndex == widget.notificationsTabIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasSelected = oldWidget.selectedTabIndex != null &&
        oldWidget.notificationsTabIndex != null &&
        oldWidget.selectedTabIndex == oldWidget.notificationsTabIndex;
    if (wasSelected && !_isSelectedTab) {
      unawaited(_onLeaveNotificationsPage());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final pending in _pendingDeletes.values) {
      pending.timer.cancel();
    }
    final leftoverIds = _pendingDeletes.keys.toList(growable: false);
    _pendingDeletes.clear();
    if (leftoverIds.isNotEmpty) {
      final service = ref.read(notificationServiceProvider);
      for (final id in leftoverIds) {
        unawaited(service.deleteNotification(id));
      }
    }
    super.dispose();
  }

  void _onScroll() {
    final cacheState = ref.read(notificationsCacheProvider);
    if (!_scrollController.hasClients ||
        cacheState.isLoadingMore ||
        cacheState.isRefreshing ||
        cacheState.showSkeleton ||
        !cacheState.hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(notificationsCacheProvider.notifier).loadMore();
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.markAsRead(notificationId);

      if (mounted) {
        ref.read(notificationsCacheProvider.notifier).markAsReadLocal(
              notificationId,
            );
        ref.read(notificationsCacheProvider.notifier).syncBadgeFromLocalList();
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to mark notification as read',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to mark notification as read',
        );
      }
    }
  }

  Future<void> _markAllAsRead({bool showErrors = true}) async {
    final hasUnread = ref
        .read(notificationsCacheProvider)
        .notifications
        .any((n) => !n.isRead);
    if (!hasUnread) return;

    ref.read(notificationsCacheProvider.notifier).markAllAsReadLocal();

    try {
      await ref.read(notificationServiceProvider).markAllAsRead();
      ref.read(notificationsCacheProvider.notifier).clearUnreadBadge();
    } on ApiError catch (e) {
      if (showErrors && mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to mark all as read',
        );
      }
    } catch (e) {
      if (showErrors && mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to mark all as read',
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final notifications = ref.read(notificationsCacheProvider).notifications;
    if (notifications.isEmpty) return;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear all notifications?',
      message: 'This removes every notification from your inbox.',
      confirmText: 'Clear all',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.deleteAllNotifications();
      if (mounted) {
        ref.read(notificationsCacheProvider.notifier).clearAllLocal();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to clear notifications',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to clear notifications',
        );
      }
    }
  }

  Future<void> _onLeaveNotificationsPage() async {
    await _commitPendingDeletes();
    final unread = ref
        .read(notificationsCacheProvider)
        .notifications
        .where((n) => !n.isRead)
        .isNotEmpty;
    if (unread) {
      await _markAllAsRead(showErrors: false);
    }
  }

  EdgeInsets _snackBarMargin(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBarReserve = AppBottomNavBar.bottomReserve(bottomInset);
    final horizontal = ResponsivePadding.horizontal(context).horizontal;
    return EdgeInsets.fromLTRB(
      horizontal,
      0,
      horizontal,
      navBarReserve + AppSpacing.spacingSM,
    );
  }

  void _showDeletedSnackBar(app_models.Notification notification) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: _undoWindow,
        margin: _snackBarMargin(context),
        content: const AppText(
          'Notification deleted · Undo',
          maxLines: 1,
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoDelete(notification.id),
        ),
      ),
    );
  }

  void _queueDelete(app_models.Notification notification) {
    final list = ref.read(notificationsCacheProvider).notifications;
    final index = list.indexWhere((n) => n.id == notification.id);
    final restoreIndex = index < 0 ? 0 : index;

    _pendingDeletes[notification.id]?.timer.cancel();
    ref.read(notificationsCacheProvider.notifier).removeLocal(notification.id);

    _pendingDeletes[notification.id] = _PendingNotificationDelete(
      notification: notification,
      index: restoreIndex,
      timer: Timer(_undoWindow, () => unawaited(_commitDelete(notification.id))),
    );

    _showDeletedSnackBar(notification);
  }

  void _undoDelete(int notificationId) {
    final pending = _pendingDeletes.remove(notificationId);
    if (pending == null) return;
    pending.timer.cancel();
    ref.read(notificationsCacheProvider.notifier).insertLocal(
          pending.notification,
          index: pending.index,
        );
  }

  Future<void> _commitDelete(int notificationId) async {
    final pending = _pendingDeletes.remove(notificationId);
    if (pending == null) return;
    pending.timer.cancel();
    try {
      await ref
          .read(notificationServiceProvider)
          .deleteNotification(notificationId);
    } catch (e) {
      AppLogger.warning(
        'Delete notification failed; restoring locally',
        tag: 'Notifications',
        error: e,
      );
      if (!mounted) return;
      ref.read(notificationsCacheProvider.notifier).insertLocal(
            pending.notification,
            index: pending.index,
          );
      ErrorHandlerService.handleError(
        context,
        Exception('Failed to delete notification'),
        customMessage: 'Failed to delete notification',
      );
    }
  }

  Future<void> _commitPendingDeletes() async {
    final ids = _pendingDeletes.keys.toList(growable: false);
    for (final id in ids) {
      await _commitDelete(id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _handleNotificationTap(app_models.Notification notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    final type = notification.type.toLowerCase();
    final restrictedLike = type.contains('like') &&
        (notification.isPlanRestricted || notification.upgradeRequired);
    if (restrictedLike) {
      final target = Uri(
        path: AppRoutes.featureLocked,
        queryParameters: {
          'title': 'See who liked you',
          'desc':
              'Upgrade to see the people who liked you and match faster.',
          'minTier': 'silder',
          'feature': 'See who liked you',
        },
      ).toString();
      context.push(target);
      return;
    }

    if (type.contains('match')) {
      unawaited(notifyNewMatch(ref));
    }

    NotificationNavigation.navigateFromNotification(context, notification);
  }

  Widget? _buildHeaderAction(
    BuildContext context,
    int unreadCount,
    List<app_models.Notification> notifications,
  ) {
    if (notifications.isEmpty) return null;

    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: AppSvgIcon(
        assetPath: AppIcons.more,
        size: 24,
        color: theme.colorScheme.onSurface,
      ),
      onSelected: (value) {
        switch (value) {
          case 'read':
            if (unreadCount > 0) _markAllAsRead();
            break;
          case 'clear':
            _clearAllNotifications();
            break;
        }
      },
      itemBuilder: (context) => [
        if (unreadCount > 0)
          const PopupMenuItem(
            value: 'read',
            child: AppText(
              'Mark all read',
              maxLines: 1,
            ),
          ),
        const PopupMenuItem(
          value: 'clear',
          child: AppText(
            'Clear all',
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  List<app_models.Notification> _filterByCategory(
    List<app_models.Notification> items,
  ) {
    if (_categoryIndex == 0) return items;
    final label = _categories[_categoryIndex].toLowerCase();
    return items.where((n) {
      final type = n.type.toLowerCase();
      return switch (label) {
        'matches' => type.contains('match'),
        'likes' => type.contains('like'),
        'views' => type.contains('view'),
        'system' => type.contains('plan') ||
            type.contains('system') ||
            type.contains('verify'),
        _ => true,
      };
    }).toList();
  }

  Widget _buildBody(NotificationsCacheState cacheState) {
    if (cacheState.showSkeleton) {
      return const SkeletonNotifications();
    }

    if (cacheState.showError) {
      return ErrorDisplayWidget(
        errorMessage: cacheState.errorMessage ?? 'Failed to load notifications',
        onRetry: () => ref.read(notificationsCacheProvider.notifier).refresh(),
      );
    }

    if (cacheState.notifications.isEmpty) {
      return ListView(
        physics: AppScroll.bouncing,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: EmptyState(
              title: 'No notifications',
              message:
                  'You\'re all caught up. Discover new people to spark activity.',
              iconPath: AppIcons.notification,
              actionLabel: 'Go to discovery',
              onAction: () => context.go('${AppRoutes.home}/discovery'),
              secondaryActionLabel: 'Contact support',
              onSecondaryAction: () => context.push(AppRoutes.helpSupport),
            ),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final notifications = _filterByCategory(cacheState.notifications);
    final footerCount = cacheState.isLoadingMore ? 1 : 0;

    return AppListView.builder(
        controller: _scrollController,
        physics: AppScroll.forPlatform(context),
        padding: ResponsivePadding.horizontal(context).copyWith(
          bottom: AppSpacing.spacingLG,
        ),
        itemCount: notifications.length + 2 + footerCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
              child: PremiumCategoryChips(
                labels: _categories,
                selectedIndex: _categoryIndex,
                subtleSelection: true,
                onSelected: (i) => setState(() => _categoryIndex = i),
              ),
            );
          }

          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
              child: AppText(
                notifications.isEmpty ? 'No activity in this category' : 'Recent',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
            );
          }

          final notificationIndex = index - 2;
          if (notificationIndex >= notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingLG),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final notification = notifications[notificationIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacingXS),
            child: NotificationTile(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onMarkAsRead: () => _markAsRead(notification.id),
              onDelete: () => _queueDelete(notification),
            ),
          );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheState = ref.watch(notificationsCacheProvider);
    final unreadCount =
        cacheState.notifications.where((n) => !n.isRead).length;

    return PremiumTabPageLayout(
      title: 'Notifications',
      subtitle: unreadCount > 0
          ? '$unreadCount unread · Stay in the loop'
          : 'Your social activity hub',
      onRefresh: () =>
          ref.read(notificationsCacheProvider.notifier).refresh(),
      action: _buildHeaderAction(
        context,
        unreadCount,
        cacheState.notifications,
      ),
      body: _buildBody(cacheState),
    );
  }
}
