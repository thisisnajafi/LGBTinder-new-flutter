// Widget: ChatHeader — premium conversation header
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';
import '../avatar/avatar_with_status.dart';
import 'last_seen_widget.dart';

/// Chat screen header with profile-aware styling.
class ChatHeader extends ConsumerWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderTap;
  final VoidCallback? onInfo;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;

  const ChatHeader({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.onBack,
    this.onHeaderTap,
    this.onInfo,
    this.onCall,
    this.onVideoCall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentViolet.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingSM,
                  ),
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
                        ),
                      GestureDetector(
                        onTap: onHeaderTap ?? onInfo,
                        behavior: HitTestBehavior.opaque,
                        child: AvatarWithStatus(
                          imageUrl: avatarUrl,
                          name: name,
                          isOnline: isOnline,
                          size: 44,
                          showRing: isOnline,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacingMD),
                      Expanded(
                        child: InkWell(
                          onTap: onHeaderTap ?? onInfo,
                          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.spacingXS,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                LastSeenWidget(
                                  isOnline: isOnline,
                                  lastSeenAt: lastSeenAt,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (onCall != null)
                        IconButton(
                          icon: AppSvgIcon(
                            assetPath: AppIcons.call,
                            size: 22,
                            color: AppColors.accentViolet,
                          ),
                          onPressed: onCall,
                        ),
                      if (onVideoCall != null)
                        IconButton(
                          icon: AppSvgIcon(
                            assetPath: AppIcons.videoCall,
                            size: 22,
                            color: AppColors.accentPink,
                          ),
                          onPressed: onVideoCall,
                        ),
                      if (onInfo != null)
                        IconButton(
                          icon: AppSvgIcon(
                            assetPath: AppIcons.infoCircle,
                            size: 22,
                            color: textColor,
                          ),
                          onPressed: onInfo,
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: AppColors.brandGradient,
                ),
              ),
            ],
      ),
    );
  }
}
