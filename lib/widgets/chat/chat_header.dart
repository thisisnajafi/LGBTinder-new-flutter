// Widget: ChatHeader
// Chat screen header with user info
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../avatar/avatar_with_status.dart';
import 'last_seen_widget.dart';

/// Chat screen header widget
/// Displays user info, avatar, online status, and actions
class ChatHeader extends ConsumerWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final VoidCallback? onBack;
  final VoidCallback? onInfo;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;

  const ChatHeader({
    Key? key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.onBack,
    this.onInfo,
    this.onCall,
    this.onVideoCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSpacing.spacingLG,
        right: AppSpacing.spacingLG,
        bottom: AppSpacing.spacingMD,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                icon: AppSvgIcon(
                  assetPath: AppIcons.arrowLeft,
                  size: 24,
                  color: textColor,
                ),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            AvatarWithStatus(
              imageUrl: avatarUrl,
              name: name,
              isOnline: isOnline,
              size: 40.0,
            ),
            SizedBox(width: AppSpacing.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTypography.h3.copyWith(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  LastSeenWidget(
                    isOnline: isOnline,
                    lastSeenAt: lastSeenAt,
                  ),
                ],
              ),
            ),
            if (onCall != null)
              IconButton(
                icon: AppSvgIcon(
                  assetPath: AppIcons.call,
                  size: 24,
                  color: textColor,
                ),
                onPressed: onCall,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            if (onVideoCall != null)
              IconButton(
                icon: AppSvgIcon(
                  assetPath: AppIcons.videoCall,
                  size: 24,
                  color: textColor,
                ),
                onPressed: onVideoCall,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            if (onInfo != null)
              IconButton(
                icon: AppSvgIcon(
                  assetPath: AppIcons.infoCircle,
                  size: 24,
                  color: textColor,
                ),
                onPressed: onInfo,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
