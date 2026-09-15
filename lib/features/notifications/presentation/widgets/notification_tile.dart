// Widget: NotificationTile
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/responsive/responsive.dart';
import '../../data/models/notification.dart' as app_models;
import 'notification_visuals.dart';

/// Notification tile widget for displaying individual notifications.
class NotificationTile extends StatefulWidget {
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

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool _pressed = false;
  bool _swiping = false;

  app_models.Notification get notification => widget.notification;

  bool get _restrictLikeIdentity {
    final type = notification.type.toLowerCase();
    return type.contains('like') &&
        (notification.isPlanRestricted || notification.upgradeRequired);
  }

  String _displayTitle() {
    if (_restrictLikeIdentity) return 'Someone liked you';
    return notification.title.isNotEmpty
        ? notification.title
        : _getDefaultTitle();
  }

  String _formatTime(DateTime dateTime) {
    return AppDateTime.formatRelative(dateTime);
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

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setSwiping(bool value) {
    if (_swiping == value) return;
    setState(() {
      _swiping = value;
      if (value) _pressed = false;
    });
  }

  Widget _buildLeadingIcon(BuildContext context) {
    const size = 48.0;
    final accent = NotificationVisuals.accentFor(notification);
    final isUserRelated = NotificationVisuals.isUserRelated(notification);
    final imageUrl = NotificationVisuals.actorImageUrl(notification);

    if (isUserRelated) {
      Widget avatar;
      if (imageUrl != null) {
        avatar = Container(
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
      } else {
        final initial = NotificationVisuals.actorInitial(notification);
        avatar = Container(
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
      if (_restrictLikeIdentity) {
        if (!AppAnimations.animationsEnabled(context)) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: AppIcons.getIconPath('profile-circle'),
                size: 24,
                color: accent,
              ),
            ),
          );
        }
        return RepaintBoundary(
          child: ClipOval(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: avatar,
            ),
          ),
        );
      }
      return avatar;
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

  Widget _buildDeleteBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.feedbackError,
              AppColors.feedbackError.withValues(alpha: 0.82),
              AppColors.accentPink.withValues(alpha: 0.72),
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingLG,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  'Delete',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingSM),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: AppIcons.getIconPath('trash'),
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final accent = NotificationVisuals.accentFor(notification);
    final animate = AppAnimations.animationsEnabled(context);
    final scale = _pressed && !_swiping && animate
        ? AppAnimations.buttonPressScale
        : 1.0;

    return RepaintBoundary(
      child: Dismissible(
      key: ValueKey('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.32,
      },
      movementDuration: AppAnimations.transitionPage,
      resizeDuration: AppAnimations.cardExit,
      background: _buildDeleteBackground(),
      confirmDismiss: (_) async {
        AppHaptics.medium();
        return true;
      },
      onUpdate: (details) {
        _setSwiping(details.progress > 0.03);
      },
      onDismissed: (_) => widget.onDelete?.call(),
      child: Semantics(
        button: true,
        label: _displayTitle(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (!_swiping) _setPressed(true);
          },
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: () {
            if (_swiping) return;
            AppHaptics.light();
            widget.onTap?.call();
          },
          child: AnimatedScale(
            scale: scale,
            duration: AppAnimations.effectiveTapDuration(context),
            curve: AppAnimations.curveDefault,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? (isDark
                        ? AppColors.cardBackgroundDark
                        : AppColors.cardBackgroundLight)
                    : theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                border: Border.all(
                  color: notification.isRead
                      ? borderColor.withValues(alpha: 0.25)
                      : accent.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepaintBoundary(child: _buildLeadingIcon(context)),
                  const SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                _displayTitle(),
                                style: AppTypography.body.copyWith(
                                  color: textColor,
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                                maxLines: 2,
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
                        AppText(
                          notification.message,
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSpacing.spacingXS),
                        AppText(
                          _formatTime(notification.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
