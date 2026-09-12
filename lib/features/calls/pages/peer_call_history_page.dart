import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/peer_avatar_cache.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_date_time.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/app_list_view.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../presentation/widgets/call_history_avatar.dart';
import '../../../features/user/providers/user_providers.dart';
import '../../../widgets/error_handling/empty_state.dart';
import '../data/models/call.dart';
import '../providers/messenger_calls_provider.dart';
import '../utils/call_log_labels.dart';
import '../utils/call_navigation.dart';
import '../utils/messenger_call_groups.dart';
import 'outgoing_call_page.dart';

/// All calls with one person, plus voice and video actions.
class PeerCallHistoryPage extends ConsumerWidget {
  const PeerCallHistoryPage({
    super.key,
    required this.peerUserId,
    required this.peerName,
    this.peerAvatarUrl,
  });

  final int peerUserId;
  final String peerName;
  final String? peerAvatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(cachedCurrentUserProvider).asData?.value.id ?? 0;
    final inbox = ref.watch(messengerCallsProvider);
    var calls = inbox.calls
        .where(
          (call) =>
              call.callerId == peerUserId || call.receiverId == peerUserId,
        )
        .toList();
    if (calls.isEmpty) {
      calls = ref.read(messengerCallsProvider.notifier).callsForPeer(peerUserId);
    }
    final cachedAvatar = ref.watch(peerAvatarCacheProvider)[peerUserId];
    final avatarUrl = MediaUrl.pick(
      userId: peerUserId,
      incoming: peerAvatarUrl ??
          (calls.isEmpty ? null : messengerPeerAvatarFromCalls(calls, me)),
      cached: cachedAvatar,
    );

    return PremiumDetailScaffold(
      title: peerName,
      subtitle: 'Call history',
      action: CallHistoryAvatar(
        size: 36,
        imageUrl: avatarUrl,
      ),
      body: calls.isEmpty
          ? EmptyState(
              title: 'No calls yet',
              message: 'Voice and video calls with $peerName will show up here.',
              iconPath: AppIcons.call,
            )
          : AppListView.separated(
              physics: AppScroll.bouncing,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacingLG,
                AppSpacing.spacingSM,
                AppSpacing.spacingLG,
                AppSpacing.spacingXL,
              ),
              itemCount: calls.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.spacingXS),
              itemBuilder: (context, index) {
                return _PeerCallHistoryTile(
                  call: calls[index],
                  currentUserId: me,
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spacingLG,
            AppSpacing.spacingSM,
            AppSpacing.spacingLG,
            AppSpacing.spacingMD,
          ),
          child: Row(
            children: [
              Expanded(
                child: _HistoryCallButton(
                  label: 'Voice',
                  iconPath: AppIcons.call,
                  onTap: () => startOutgoingCall(
                    context: context,
                    ref: ref,
                    recipientId: peerUserId,
                    recipientName: peerName,
                    recipientAvatarUrl: avatarUrl,
                    type: OutgoingCallType.voice,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: _HistoryCallButton(
                  label: 'Video',
                  iconPath: AppIcons.video,
                  onTap: () => startOutgoingCall(
                    context: context,
                    ref: ref,
                    recipientId: peerUserId,
                    recipientName: peerName,
                    recipientAvatarUrl: avatarUrl,
                    type: OutgoingCallType.video,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeerCallHistoryTile extends StatelessWidget {
  const _PeerCallHistoryTile({
    required this.call,
    required this.currentUserId,
  });

  final Call call;
  final int currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final negative = CallLogLabels.isMissedOrDeclined(
      call: call,
      currentUserId: currentUserId,
    );
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final label = CallLogLabels.title(call: call, currentUserId: currentUserId);

    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: negative
                        ? AppColors.feedbackError
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXS),
                Text(
                  AppDateTime.formatRelative(call.timelineTimestamp),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          AppSvgIcon(
            assetPath: call.isVideoCall ? AppIcons.video : AppIcons.call,
            size: 22,
            color: negative ? AppColors.feedbackError : AppColors.accentViolet,
          ),
        ],
      ),
    );
  }
}

class _HistoryCallButton extends StatelessWidget {
  const _HistoryCallButton({
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumTapScale(
      onTap: onTap,
      semanticLabel: '$label call',
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentViolet, AppColors.accentPink],
          ),
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSvgIcon(
              assetPath: iconPath,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: AppSpacing.spacingSM),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
