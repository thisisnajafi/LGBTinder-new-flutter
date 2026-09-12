// Screen: CallHistoryScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_list_view.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/calls/presentation/widgets/call_history_avatar.dart';
import '../widgets/error_handling/empty_state.dart';
import '../widgets/loading/skeleton_loader.dart';
import '../pages/chat_page.dart';
import '../features/calls/providers/call_provider.dart';
import '../features/calls/data/models/call.dart';
import '../features/user/providers/user_providers.dart';
import '../core/responsive/responsive.dart';

/// Call history screen - View call history
class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  bool _isLoading = false;
  List<Call> _calls = [];

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      await ref.read(callProvider.notifier).loadCallHistory(limit: 50);
      if (!mounted) return;
      setState(() {
        _calls = ref.read(callProvider).callHistory;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Call call) {
    if (call.isMissed || call.duration == null || call.duration!.inSeconds == 0) {
      return 'Missed';
    }
    return call.formattedDuration;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(
      cachedCurrentUserProvider.select((a) => a.asData?.value.id ?? 0),
    );

    return AppSettingsDetailScaffold(
      title: 'Call history',
      subtitle: 'Recent voice and video calls',
      onRefresh: _isLoading ? null : _loadCallHistory,
      action: IconButton(
        icon: AppSvgIcon(
          assetPath: AppIcons.getIconPath('refresh'),
          size: 22,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: _loadCallHistory,
      ),
      body: _isLoading
          ? AppListView.builder(
              physics: AppScroll.bouncing,
              itemCount: 5,
              padding: const EdgeInsets.all(AppSpacing.spacingLG),
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80,
                    borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  ),
                );
              },
            )
          : _calls.isEmpty
              ? const EmptyState(
                  title: 'No call history',
                  message: 'Your call history will appear here',
                  iconPath: AppIcons.call,
                )
              : AppListView.builder(
                  physics: AppScroll.bouncing,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.spacingLG,
                    AppSpacing.spacingSM,
                    AppSpacing.spacingLG,
                    AppSpacing.spacingXXL,
                  ),
                  itemCount: _calls.length,
                  itemBuilder: (context, index) {
                    final call = _calls[index];
                    return _CallHistoryRow(
                      call: call,
                      currentUserId: me,
                      formatDuration: _formatDuration,
                      formatTime: _formatTime,
                      onOpenChat: () {
                        final isOutgoing = call.callerId == me;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              userId: isOutgoing
                                  ? call.receiverId
                                  : call.callerId,
                            ),
                          ),
                        );
                      },
                      onCallAgain: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Call initiation will be implemented',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class _CallHistoryRow extends StatelessWidget {
  const _CallHistoryRow({
    required this.call,
    required this.currentUserId,
    required this.formatDuration,
    required this.formatTime,
    required this.onOpenChat,
    required this.onCallAgain,
  });

  final Call call;
  final int currentUserId;
  final String Function(Call) formatDuration;
  final String Function(DateTime) formatTime;
  final VoidCallback onOpenChat;
  final VoidCallback onCallAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final isMissed = call.status == 'missed';
    final isOutgoing = call.callerId == currentUserId;
    final callIcon =
        call.isVideoCall ? AppIcons.video : AppIcons.call;
    final directionIcon = isOutgoing
        ? AppIcons.callOutgoing
        : AppIcons.callIncoming;
    final iconColor = isMissed
        ? AppColors.feedbackError
        : (isOutgoing ? AppColors.onlineGreen : AppColors.accentViolet);
    final displayName = isOutgoing
        ? '${call.receiver?.firstName ?? 'Unknown'} ${call.receiver?.lastName ?? 'User'}'
        : '${call.caller?.firstName ?? 'Unknown'} ${call.caller?.lastName ?? 'User'}';

    return PremiumTapScale(
      onTap: onOpenChat,
      semanticLabel: 'Open chat with $displayName',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
        padding: const EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
          ),
        ),
        child: Row(
          children: [
            CallHistoryAvatar(
              size: 52,
              imageUrl: isOutgoing
                  ? call.receiver?.avatarUrl
                  : call.caller?.avatarUrl,
            ),
            const SizedBox(width: AppSpacing.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppSvgIcon(
                        assetPath: directionIcon,
                        size: 14,
                        color: iconColor,
                      ),
                      const SizedBox(width: AppSpacing.spacingXS),
                      Expanded(
                        child: AppText(
                          displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isMissed
                                ? AppColors.feedbackError
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacingXS),
                  Row(
                    children: [
                      AppSvgIcon(
                        assetPath: callIcon,
                        size: 14,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: AppSpacing.spacingXS),
                      Text(
                        formatDuration(call),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatTime(call.startedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                IconButton(
                  icon: AppSvgIcon(
                    assetPath: callIcon,
                    size: 22,
                    color: AppColors.accentViolet,
                  ),
                  onPressed: onCallAgain,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
