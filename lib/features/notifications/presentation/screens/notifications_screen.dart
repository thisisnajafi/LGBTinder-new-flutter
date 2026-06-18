// Screen: NotificationsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/utils/app_icons.dart';
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
import '../../../../shared/services/notification_navigation.dart';

/// Notifications screen - Displays all user notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        ref.invalidate(unreadNotificationCountProvider);
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

  Future<void> _markAllAsRead() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.markAllAsRead();

      if (mounted) {
        ref.read(notificationsCacheProvider.notifier).markAllAsReadLocal();
        ref.invalidate(unreadNotificationCountProvider);
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to mark all as read',
        );
      }
    } catch (e) {
      if (mounted) {
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
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.deleteAllNotifications();
      if (mounted) {
        ref.read(notificationsCacheProvider.notifier).clearAllLocal();
        ref.invalidate(unreadNotificationCountProvider);
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

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.deleteNotification(notificationId);

      if (mounted) {
        ref.read(notificationsCacheProvider.notifier).removeLocal(
              notificationId,
            );
        ref.invalidate(unreadNotificationCountProvider);
      }
    } on ApiError catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to delete notification',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to delete notification',
        );
      }
    }
  }

  void _handleNotificationTap(app_models.Notification notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
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
            child: Text('Mark all read'),
          ),
        const PopupMenuItem(
          value: 'clear',
          child: Text('Clear all'),
        ),
      ],
    );
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
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsCacheProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      );
    }

    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final notifications = cacheState.notifications;
    final footerCount = cacheState.isLoadingMore ? 1 : 0;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationsCacheProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppPageHeader.horizontalPadding,
          0,
          AppPageHeader.horizontalPadding,
          AppSpacing.spacingLG,
        ),
        itemCount: notifications.length + 1 + footerCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
              child: Text(
                'Recent',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final notificationIndex = index - 1;
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
              onDelete: () => _deleteNotification(notification.id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final cacheState = ref.watch(notificationsCacheProvider);
    final unreadCount =
        cacheState.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Notifications',
              action: _buildHeaderAction(
                context,
                unreadCount,
                cacheState.notifications,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            Expanded(
              child: _buildBody(cacheState),
            ),
          ],
        ),
      ),
    );
  }
}
