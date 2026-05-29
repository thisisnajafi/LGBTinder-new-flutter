// Screen: NotificationsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/notification.dart' as app_models;
import '../../providers/notification_providers.dart';
import '../widgets/notification_tile.dart';
import '../../../../widgets/error_handling/empty_state.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/services/notification_navigation.dart';

/// Notifications screen - Displays all user notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;
  String? _errorMessage;
  List<app_models.Notification> _notifications = [];
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore || !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;

    setState(() {
      if (refresh || _notifications.isEmpty) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final notificationService = ref.read(notificationServiceProvider);
      final notifications = await notificationService.getNotifications(
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = notifications;
          } else {
            final existingIds = _notifications.map((e) => e.id).toSet();
            _notifications.addAll(
              notifications.where((n) => !existingIds.contains(n.id)),
            );
          }
          _hasMore = notifications.length >= _pageSize;
          if (_hasMore) _currentPage++;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.markAsRead(notificationId);

      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = app_models.Notification(
              id: _notifications[index].id,
              type: _notifications[index].type,
              title: _notifications[index].title,
              message: _notifications[index].message,
              createdAt: _notifications[index].createdAt,
              isRead: true,
              data: _notifications[index].data,
              userId: _notifications[index].userId,
              userImageUrl: _notifications[index].userImageUrl,
              actionUrl: _notifications[index].actionUrl,
            );
          }
        });
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
        setState(() {
          _notifications = _notifications.map((n) {
            return app_models.Notification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              createdAt: n.createdAt,
              isRead: true,
              data: n.data,
              userId: n.userId,
              userImageUrl: n.userImageUrl,
              actionUrl: n.actionUrl,
            );
          }).toList();
        });
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
    if (_notifications.isEmpty) return;
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.deleteAllNotifications();
      if (mounted) {
        setState(() {
          _notifications.clear();
          _currentPage = 1;
          _hasMore = true;
        });
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
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
        });
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

  Widget? _buildHeaderAction(BuildContext context, int unreadCount) {
    if (_notifications.isEmpty) return null;

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

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _notifications.isEmpty) {
      return const SkeletonLoading();
    }

    if (_hasError && _notifications.isEmpty) {
      return ErrorDisplayWidget(
        errorMessage: _errorMessage ?? 'Failed to load notifications',
        onRetry: () => _loadNotifications(refresh: true),
      );
    }

    if (_notifications.isEmpty) {
      return EmptyState(
        title: 'No notifications',
        message:
            'You\'re all caught up. Discover new people to spark activity.',
        iconPath: AppIcons.notification,
        actionLabel: 'Go to discovery',
        onAction: () => context.go('${AppRoutes.home}/discovery'),
        secondaryActionLabel: 'Contact support',
        onSecondaryAction: () => context.push(AppRoutes.helpSupport),
      );
    }

    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppPageHeader.horizontalPadding,
          0,
          AppPageHeader.horizontalPadding,
          AppSpacing.spacingLG,
        ),
        itemCount: _notifications.length + 1 + (_isLoadingMore ? 1 : 0),
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
          if (notificationIndex >= _notifications.length) {
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

          final notification = _notifications[notificationIndex];
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
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Notifications',
              action: _buildHeaderAction(context, unreadCount),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }
}
