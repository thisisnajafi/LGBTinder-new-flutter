// Widget: ChatHeader — premium conversation header
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../../core/widgets/profile_image_widget.dart';
import 'last_seen_widget.dart';

/// Chat screen header with profile-aware premium styling.
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
        color:
            isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
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
                    PremiumTapScale(
                      onTap: onBack!,
                      semanticLabel: 'Back',
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.spacingXS),
                        child: AppSvgIcon(
                          assetPath: AppIcons.arrowLeft,
                          size: 24,
                          color: textColor,
                        ),
                      ),
                    ),
                  PremiumTapScale(
                    onTap: onHeaderTap ?? onInfo ?? () {},
                    semanticLabel: 'Open $name profile',
                    child: _HeaderAvatar(
                      imageUrl: avatarUrl,
                      isOnline: isOnline,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: PremiumTapScale(
                      onTap: onHeaderTap ?? onInfo ?? () {},
                      semanticLabel: 'Chat with $name',
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
                                letterSpacing: -0.2,
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
                    _HeaderAction(
                      iconPath: AppIcons.call,
                      color: AppColors.accentViolet,
                      label: 'Voice call',
                      onTap: onCall!,
                    ),
                  if (onVideoCall != null)
                    _HeaderAction(
                      iconPath: AppIcons.videoCall,
                      color: AppColors.accentRose,
                      label: 'Video call',
                      onTap: onVideoCall!,
                    ),
                  if (onInfo != null)
                    _HeaderAction(
                      iconPath: AppIcons.infoCircle,
                      color: AppColors.accentViolet,
                      label: 'Chat info',
                      onTap: onInfo!,
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

class _HeaderAvatar extends ConsumerWidget {
  const _HeaderAvatar({
    required this.imageUrl,
    required this.isOnline,
  });

  final String? imageUrl;
  final bool isOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isOnline)
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
              ),
            ),
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
            ),
            child: ClipOval(
              child: ProfileImageWidget(
                imageUrl: imageUrl,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.iconPath,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final String iconPath;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.spacingXS),
      child: PremiumTapScale(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Center(
            child: AppSvgIcon(assetPath: iconPath, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
