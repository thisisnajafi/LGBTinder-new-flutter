// Widget: AppBarCustom
// Custom app bar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../badges/notification_badge.dart';

/// Custom app bar widget
/// Styled app bar with title, actions, and optional notification badge
class AppBarCustom extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final int? notificationCount;
  final VoidCallback? onNotificationTap;

  const AppBarCustom({
    Key? key,
    this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.notificationCount,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final List<Widget> appBarActions = [];
    if (notificationCount != null && notificationCount! > 0) {
      appBarActions.add(
        GestureDetector(
          onTap: onNotificationTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: AppSvgIcon(
                  assetPath: AppIcons.notification,
                  size: 24,
                  color: textColor,
                ),
                onPressed: onNotificationTap,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: NotificationBadge(count: notificationCount!),
              ),
            ],
          ),
        ),
      );
    }
    if (actions != null) {
      appBarActions.addAll(actions!);
    }

    return AppBar(
      backgroundColor: surfaceColor,
      elevation: 0,
      leading: leading ??
          (showBackButton
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: AppSvgIcon(
                    assetPath: AppIcons.arrowLeft,
                    size: 24,
                    color: textColor,
                  ),
                  onPressed: () {
                    // Use go_router's pop method, with fallback to Navigator if needed
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      // If there's no route to pop, navigate to welcome screen
                      context.go('/welcome');
                    }
                  },
                )
              : null),
      title: title != null
          ? Text(
              title!,
              style: AppTypography.h2.copyWith(color: textColor),
            )
          : null,
      actions: appBarActions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: borderColor,
        ),
      ),
    );
  }
}
