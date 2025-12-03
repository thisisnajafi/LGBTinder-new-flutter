// Widget: NotificationTile
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../data/models/notification.dart' as app_models;
import 'package:intl/intl.dart';

/// Notification tile widget for displaying individual notifications
class NotificationTile extends StatelessWidget {
  final app_models.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationTile({
    Key? key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  }) : super(key: key);

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'like':
        return Icons.favorite;
      case 'match':
        return Icons.favorite;
      case 'superlike':
        return Icons.star;
      case 'message':
        return Icons.message;
      case 'view':
        return Icons.visibility;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case 'like':
      case 'match':
        return AppColors.accentRed;
      case 'superlike':
        return AppColors.accentYellow;
      case 'message':
        return AppColors.accentPurple;
      default:
        return AppColors.accentPurple;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        ),
        child: Icon(
          Icons.delete_outline,
          color: AppColors.accentRed,
        ),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.spacingSM),
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          decoration: BoxDecoration(
            color: notification.isRead ? surfaceColor : surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(
              color: notification.isRead ? borderColor : _getNotificationColor().withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(),
                  color: _getNotificationColor(),
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.isNotEmpty
                                ? notification.title
                                : _getDefaultTitle(),
                            style: AppTypography.body.copyWith(
                              color: textColor,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getNotificationColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      notification.message,
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      _formatTime(notification.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // User image (if available)
              if (notification.userImageUrl != null)
                Container(
                  margin: EdgeInsets.only(left: AppSpacing.spacingSM),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      notification.userImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: secondaryTextColor,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDefaultTitle() {
    switch (notification.type) {
      case 'like':
        return 'New Like';
      case 'match':
        return 'It\'s a Match!';
      case 'superlike':
        return 'Superlike Received';
      case 'message':
        return 'New Message';
      case 'view':
        return 'Profile Viewed';
      default:
        return 'Notification';
    }
  }
}
