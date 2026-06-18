import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';
import '../../features/profile/providers/profile_page_cache_provider.dart';
import '../../widgets/badges/notification_badge.dart';
import '../../widgets/buttons/scale_tap_feedback.dart';
import 'profile_image_widget.dart';

/// Floating bottom navigation bar with icon-only items and active pill highlight.
class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? messengerUnreadCount;
  final int? notificationCount;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.messengerUnreadCount,
    this.notificationCount,
  });

  static const int itemCount = 5;
  static const int messengerTabIndex = 1;
  static const int notificationsTabIndex = 2;
  static const int profileTabIndex = 3;
  static const double barHeight = 64.0;
  static const double floatingHorizontalMargin = 16.0;
  static const double floatingBottomMargin = 8.0;
  static const double _borderWidth = 1.75;

  /// Bottom padding reserved for tab content (bar + float inset + safe area).
  static double bottomReserve(double safeAreaBottom) =>
      barHeight + floatingBottomMargin + safeAreaBottom + (_borderWidth * 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveIconColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.40);
    final profileData = ref.watch(profilePageCacheProvider).valueOrNull?.profile;
    final profileAvatarUrl = profileData?.images?.isNotEmpty == true
        ? profileData!.images!.first.imageUrl
        : null;
    final profileIsOnline = profileData?.isOnline ?? true;
    final innerRadius = 100 - _borderWidth;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          floatingHorizontalMargin,
          0,
          floatingHorizontalMargin,
          floatingBottomMargin,
        ),
        child: _GradientNavBarShell(
          isDark: isDark,
          borderWidth: _borderWidth,
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(innerRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.72),
                width: 0.75,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(itemCount, (index) {
                final isActive = currentIndex == index;
                final outlinePath = AppIcons.mainNavIconOutline(index);
                final activePath = AppIcons.mainNavIconActive(index);
                final label = AppIcons.mainNavItems[index].label;
                final useProfileAvatar = index == profileTabIndex &&
                    isActive &&
                    profileAvatarUrl != null;

                return Expanded(
                  child: _NavItem(
                    label: label,
                    outlinePath: outlinePath,
                    activePath: activePath,
                    isActive: isActive,
                    inactiveIconColor: inactiveIconColor,
                    iconOverride: useProfileAvatar
                        ? _ProfileNavAvatar(
                            imageUrl: profileAvatarUrl,
                            isOnline: profileIsOnline,
                          )
                        : null,
                    badge: _badgeForTab(
                      index: index,
                      messengerUnreadCount: messengerUnreadCount,
                      notificationCount: notificationCount,
                    ),
                    onTap: () => onTap(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  static Widget? _badgeForTab({
    required int index,
    required int? messengerUnreadCount,
    required int? notificationCount,
  }) {
    if (index == messengerTabIndex &&
        messengerUnreadCount != null &&
        messengerUnreadCount > 0) {
      return NotificationBadge(count: messengerUnreadCount, size: 16);
    }
    if (index == notificationsTabIndex &&
        notificationCount != null &&
        notificationCount > 0) {
      return NotificationBadge(count: notificationCount, size: 16);
    }
    return null;
  }
}

/// Rose → violet gradient ring with soft brand glow.
class _GradientNavBarShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final double borderWidth;

  const _GradientNavBarShell({
    required this.child,
    required this.isDark,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.accentRose.withValues(alpha: 0.92),
                  AppColors.accentPurple.withValues(alpha: 0.95),
                  AppColors.lgbtGradient[4].withValues(alpha: 0.88),
                ]
              : [
                  AppColors.accentRose.withValues(alpha: 0.72),
                  AppColors.accentPurple.withValues(alpha: 0.82),
                  AppColors.accentPink.withValues(alpha: 0.68),
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: isDark ? 0.28 : 0.2),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: isDark ? 0.14 : 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: child,
      ),
    );
  }
}

class _ProfileNavAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isOnline;

  const _ProfileNavAvatar({
    required this.imageUrl,
    required this.isOnline,
  });

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: ProfileImageWidget(
                imageUrl: imageUrl,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String outlinePath;
  final String activePath;
  final bool isActive;
  final Color inactiveIconColor;
  final Widget? iconOverride;
  final Widget? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.outlinePath,
    required this.activePath,
    required this.isActive,
    required this.inactiveIconColor,
    this.iconOverride,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    return ScaleTapFeedback(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: iconOverride != null ? 12 : 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  iconOverride ??
                      AppSvgIcon(
                        assetPath: isActive ? activePath : outlinePath,
                        size: 24,
                        color: isActive ? activeColor : inactiveIconColor,
                      ),
                  if (badge != null)
                    Positioned(
                      top: -2,
                      right: iconOverride != null ? -4 : -6,
                      child: badge!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
