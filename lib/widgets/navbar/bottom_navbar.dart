// Widget: BottomNavbar
// Bottom navigation bar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';
import '../badges/notification_badge.dart';
import '../buttons/scale_tap_feedback.dart';

/// Bottom navigation bar widget
/// Glass-style bottom navigation with 5 main tabs
class BottomNavbar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int? notificationCount;

  const BottomNavbar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final activeColor = AppColors.accentPurple;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                svgIcon: AppIcons.discover,
                label: 'Discover',
                index: 0,
                textColor: textColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                svgIcon: AppIcons.message,
                label: 'Chat',
                index: 1,
                textColor: textColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                badge: notificationCount != null && notificationCount! > 0
                    ? NotificationBadge(count: notificationCount!)
                    : null,
              ),
              _buildNavItem(
                context: context,
                svgIcon: AppIcons.notification,
                label: 'Notifications',
                index: 2,
                textColor: textColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                svgIcon: AppIcons.user,
                label: 'Profile',
                index: 3,
                textColor: textColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildNavItem(
                context: context,
                svgIcon: AppIcons.settings,
                label: 'Settings',
                index: 4,
                textColor: textColor,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    IconData? icon,
    String? svgIcon,
    required String label,
    required int index,
    required Color textColor,
    required Color activeColor,
    required Color inactiveColor,
    Widget? badge,
  }) {
    final isActive = currentIndex == index;
    final iconColor = isActive ? activeColor : inactiveColor;

    final iconWidget = svgIcon != null
        ? AppSvgIcon(
            assetPath: svgIcon,
            size: 24,
            color: isActive ? Colors.white : inactiveColor,
          )
        : Icon(
            icon!,
            color: isActive ? Colors.white : inactiveColor,
            size: 24,
          );

    return Expanded(
      child: ScaleTapFeedback(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingSM),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: isActive
                      ? ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => AppColors.prideGradient.createShader(bounds),
                          child: iconWidget,
                        )
                      : iconWidget,
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: badge,
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.spacingXS),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: iconColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            // Thin gradient underline for active tab only
            if (isActive) ...[
              SizedBox(height: AppSpacing.spacingXS),
              Container(
                width: 24,
                height: 2,
                decoration: const BoxDecoration(
                  gradient: AppColors.prideGradient,
                  borderRadius: BorderRadius.all(Radius.circular(1)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

