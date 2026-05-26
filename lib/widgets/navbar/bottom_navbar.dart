// Widget: BottomNavbar
// Floating glassmorphism bottom navigation with rainbow border
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../badges/notification_badge.dart';
import '../buttons/scale_tap_feedback.dart';

/// Floating glass bottom navigation — no pill behind active tab; icon + label only.
class BottomNavbar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? notificationCount;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount,
  });

  static const int itemCount = 5;
  static const double _maxBarWidth = 520;
  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;

    final horizontalInset = width < 360
        ? AppSpacing.spacingMD
        : width < 600
            ? AppSpacing.spacingLG
            : AppSpacing.spacingXL;
    final barHeight = width < 360 ? 62.0 : 68.0;
    final barRadius = barHeight / 2;
    final iconSize = width < 360 ? 22.0 : 24.0;
    final labelSize = width < 360 ? 9.0 : 10.0;
    final compactLabels = width < 380;

    final glassFill = isDark
        ? const Color(0xFF27272A).withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.75);
    final inactiveIcon = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : AppColors.textTertiaryLight;
    final inactiveLabel = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.textSecondaryLight;
    final activeColor = isDark ? Colors.white : AppColors.accentPurple;

    // Column(min) + bottom align: never vertically center inside Scaffold slot.
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalInset),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxBarWidth),
                child: _RainbowGlassShell(
                  borderRadius: barRadius,
                  borderWidth: _borderWidth,
                  isDark: isDark,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(barRadius - _borderWidth),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: barHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: width < 360 ? 4 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: glassFill,
                          borderRadius:
                              BorderRadius.circular(barRadius - _borderWidth),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.3 : 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: List.generate(itemCount, (index) {
                            final meta = AppIcons.mainNavItems[index];
                            final label =
                                _labelForIndex(index, meta.label, compactLabels);
                            return Expanded(
                              child: _NavItem(
                                label: label,
                                outlinePath: AppIcons.mainNavIconOutline(index),
                                activePath: AppIcons.mainNavIconActive(index),
                                isActive: currentIndex == index,
                                iconSize: iconSize,
                                labelSize: labelSize,
                                activeColor: activeColor,
                                inactiveIconColor: inactiveIcon,
                                inactiveLabelColor: inactiveLabel,
                                badge: index == 1 &&
                                        notificationCount != null &&
                                        notificationCount! > 0
                                    ? NotificationBadge(count: notificationCount!)
                                    : null,
                                onTap: () => onTap(index),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelForIndex(int index, String full, bool compact) {
    if (!compact) return full;
    switch (index) {
      case 2:
        return 'Alerts';
      case 0:
        return 'Discover';
      case 1:
        return 'Chat';
      case 3:
        return 'Profile';
      case 4:
        return 'Settings';
      default:
        return full;
    }
  }
}

/// Pride-gradient outer ring.
class _RainbowGlassShell extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final bool isDark;

  const _RainbowGlassShell({
    required this.child,
    required this.borderRadius,
    required this.borderWidth,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const SweepGradient(
          colors: [
            Color(0xFF2A9D8F),
            Color(0xFFE9C46A),
            Color(0xFFE76F51),
            Color(0xFFD62828),
            Color(0xFF6A4C93),
            Color(0xFF457B9D),
            Color(0xFF2A9D8F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: isDark ? 0.2 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: child,
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String outlinePath;
  final String activePath;
  final bool isActive;
  final double iconSize;
  final double labelSize;
  final Color activeColor;
  final Color inactiveIconColor;
  final Color inactiveLabelColor;
  final Widget? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.outlinePath,
    required this.activePath,
    required this.isActive,
    required this.iconSize,
    required this.labelSize,
    required this.activeColor,
    required this.inactiveIconColor,
    required this.inactiveLabelColor,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTapFeedback(
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AppSvgIcon(
                    assetPath: isActive ? activePath : outlinePath,
                    size: iconSize,
                    color: isActive ? activeColor : inactiveIconColor,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: badge!,
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.spacingXS),
              AnimatedDefaultTextStyle(
                duration: AppAnimations.transitionModal,
                curve: AppAnimations.curveDefault,
                style: AppTypography.caption.copyWith(
                  fontSize: labelSize,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveLabelColor,
                  height: 1.1,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
