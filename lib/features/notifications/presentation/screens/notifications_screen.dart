// Screen: NotificationsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/notification.dart' as app_models;
import '../../providers/notification_providers.dart';
import '../widgets/notification_tile.dart';
import '../../../../pages/chat_page.dart';
import '../../../../pages/profile_page.dart';

/// Notifications screen - Displays all user notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  List<app_models.Notification> _notifications = [];
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
    }

    setState(() {
      _isLoading = true;
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
            _notifications.addAll(notifications);
          }
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
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

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.deleteNotification(notificationId);

      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
        });
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
    // Mark as read if not already read
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Navigate based on notification type
    if (notification.actionUrl != null) {
      context.go(notification.actionUrl!);
      return;
    }

    switch (notification.type) {
      case 'match':
      case 'like':
      case 'superlike':
        if (notification.userId != null) {
          context.go('/home/profile?userId=${notification.userId}');
        }
        break;
      case 'message':
        if (notification.userId != null) {
          context.go('/chat?userId=${notification.userId}');
        }
        break;
      default:
        // Do nothing for other types
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: AppTypography.button.copyWith(
                  color: AppColors.accentPurple,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? SkeletonLoading()
          : _hasError && _notifications.isEmpty
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage ?? 'Failed to load notifications',
                  onRetry: () => _loadNotifications(refresh: true),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          Text(
                            'No notifications',
                            style: AppTypography.h3.copyWith(color: textColor),
                          ),
                          SizedBox(height: AppSpacing.spacingSM),
                          Text(
                            'You\'re all caught up!',
                            style: AppTypography.body.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadNotifications(refresh: true),
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.spacingMD),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index] as app_models.Notification;
                          return NotificationTile(
                            notification: notification,
                            onTap: () => _handleNotificationTap(notification),
                            onMarkAsRead: () => _markAsRead(notification.id),
                            onDelete: () => _deleteNotification(notification.id),
                          );
                        },
                      ),
                    ),
    );
  }
}
