// Widget: NotificationTile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../data/models/notification.dart' as app_models;
import 'notification_visuals.dart';

/// Notification tile widget for displaying individual notifications.
class NotificationTile extends ConsumerWidget {
  final app_models.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

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

  String _getDefaultTitle() {
    switch (notification.type) {
      case 'like':
        return 'New Like';
      case 'match':
        return "It's a Match!";
      case 'superlike':
      case 'superlike_sent':
        return 'Superlike';
      case 'message':
        return 'New Message';
      case 'view':
      case 'profile_view':
        return 'Profile Viewed';
      case 'plan_granted':
      case 'plan_upgraded':
        return 'Plan Updated';
      default:
        return 'Notification';
    }
  }

  Widget _buildLeadingIcon(BuildContext context) {
    const size = 48.0;
    final accent = NotificationVisuals.accentFor(notification);
    final isUserRelated = NotificationVisuals.isUserRelated(notification);
    final imageUrl = NotificationVisuals.actorImageUrl(notification);

    if (isUserRelated) {
      if (imageUrl != null) {
        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                accent,
                AppColors.accentViolet.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
            ),
            child: ClipOval(
              child: AvatarWidget(
                imageUrl: imageUrl,
                radius: 21,
                fallbackInitial: NotificationVisuals.actorInitial(notification),
              ),
            ),
          ),
        );
      }

      final initial = NotificationVisuals.actorInitial(notification);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: initial != null
              ? Text(
                  initial,
                  style: AppTypography.labelMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : AppSvgIcon(
                  assetPath: AppIcons.getIconPath('profile-circle'),
                  size: 24,
                  color: accent,
                ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Center(
        child: AppSvgIcon(
          assetPath: NotificationVisuals.iconAssetFor(notification),
          size: 22,
          color: accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final accent = NotificationVisuals.accentFor(notification);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.spacingLG),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        ),
        child: AppSvgIcon(
          assetPath: AppIcons.getIconPath('trash'),
          size: 22,
          color: AppColors.accentRed,
        ),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
          padding: const EdgeInsets.all(AppSpacing.spacingMD),
          decoration: BoxDecoration(
            color: notification.isRead
                ? surfaceColor
                : surfaceColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(
              color: notification.isRead
                  ? borderColor.withValues(alpha: 0.45)
                  : accent.withValues(alpha: 0.28),
              width: notification.isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeadingIcon(context),
              const SizedBox(width: AppSpacing.spacingMD),
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
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      notification.message,
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
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
            ],
          ),
        ),
      ),
    );
  }
}
