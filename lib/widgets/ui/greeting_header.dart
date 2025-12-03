// Widget: GreetingHeader
// Greeting header with avatar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../avatar/avatar_with_status.dart';

/// Greeting header widget
/// Displays personalized greeting with user avatar
class GreetingHeader extends ConsumerWidget {
  final String userName;
  final String? avatarUrl;
  final String? subtitle;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;
  final int? notificationCount;

  const GreetingHeader({
    Key? key,
    required this.userName,
    this.avatarUrl,
    this.subtitle,
    this.onAvatarTap,
    this.onNotificationTap,
    this.notificationCount,
  }) : super(key: key);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: AvatarWithStatus(
              imageUrl: avatarUrl,
              name: userName,
              isOnline: false,
              size: 56.0,
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $userName',
                  style: AppTypography.h2.copyWith(color: textColor),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    subtitle!,
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                  ),
                ],
              ],
            ),
          ),
          if (onNotificationTap != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: textColor,
                  ),
                  onPressed: onNotificationTap,
                ),
                if (notificationCount != null && notificationCount! > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.notificationRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationCount! > 99 ? '99+' : '${notificationCount!}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
