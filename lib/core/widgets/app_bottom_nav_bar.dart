import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';
import '../../widgets/badges/notification_badge.dart';
import '../../widgets/buttons/scale_tap_feedback.dart';

/// Flat bottom navigation bar with icon-only items and active pill highlight.
class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? notificationCount;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount,
  });

  static const int itemCount = 5;
  static const double barHeight = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inactiveIconColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.40);

    return SafeArea(
      top: false,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
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

            return Expanded(
              child: _NavItem(
                label: label,
                outlinePath: outlinePath,
                activePath: activePath,
                isActive: isActive,
                inactiveIconColor: inactiveIconColor,
                badge: index == 1 &&
                        notificationCount != null &&
                        notificationCount! > 0
                    ? NotificationBadge(
                        count: notificationCount!,
                        size: 16,
                      )
                    : null,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
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
  final Widget? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.outlinePath,
    required this.activePath,
    required this.isActive,
    required this.inactiveIconColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  AppSvgIcon(
                    assetPath: isActive ? activePath : outlinePath,
                    size: 24,
                    color: isActive ? activeColor : inactiveIconColor,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -2,
                      right: -6,
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
