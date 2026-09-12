import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../core/responsive/responsive.dart';
import 'call_history_avatar.dart';
import '../../utils/call_log_labels.dart';
import '../../utils/messenger_call_groups.dart';

/// One person in the messenger Calls list.
class MessengerCallRow extends StatelessWidget {
  final MessengerCallGroup group;
  final int currentUserId;
  final VoidCallback onOpenHistory;
  final VoidCallback onCallAgain;

  const MessengerCallRow({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.onOpenHistory,
    required this.onCallAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final call = group.latest;
    final negative = CallLogLabels.isMissedOrDeclined(
      call: call,
      currentUserId: currentUserId,
    );
    final live = CallLogLabels.isLiveStatus(call.status);
    final subtitle = CallLogLabels.listSubtitle(
      call: call,
      currentUserId: currentUserId,
      count: group.count,
      missedCount: group.missedCount,
    );
    final accent = negative
        ? AppColors.feedbackError
        : (live ? AppColors.onlineGreen : theme.colorScheme.onSurface);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return PremiumTapScale(
      onTap: onOpenHistory,
      semanticLabel: '${group.peerName}, $subtitle',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: negative
                ? AppColors.feedbackError.withValues(alpha: 0.22)
                : AppColors.accentViolet.withValues(alpha: isDark ? 0.1 : 0.08),
          ),
        ),
        child: Row(
          children: [
            CallHistoryAvatar(
              size: 52,
              imageUrl: group.peerAvatarUrl,
            ),
            const SizedBox(width: AppSpacing.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    group.peerName,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: negative ? AppColors.feedbackError : accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: negative ? AppColors.feedbackError : muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppDateTime.formatRelative(call.startedAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                Semantics(
                  button: true,
                  label: call.isVideoCall
                      ? 'Video call ${group.peerName}'
                      : 'Voice call ${group.peerName}',
                  child: IconButton(
                    tooltip: call.isVideoCall ? 'Video call' : 'Voice call',
                    onPressed: onCallAgain,
                    icon: AppSvgIcon(
                      assetPath:
                          call.isVideoCall ? AppIcons.video : AppIcons.call,
                      size: 22,
                      color: AppColors.accentViolet,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
