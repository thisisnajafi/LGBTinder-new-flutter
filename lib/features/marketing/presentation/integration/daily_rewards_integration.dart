import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../providers/marketing_providers.dart';
import '../widgets/daily_rewards_dialog.dart';

/// Daily rewards button for profile/home screens
/// Part of the Marketing System Implementation (Task 3.6.2)
/// 
/// Usage:
/// ```dart
/// DailyRewardsButton()
/// DailyRewardsButton.compact()
/// DailyRewardsButton.card()
/// ```
class DailyRewardsButton extends ConsumerWidget {
  final bool compact;
  final bool showCard;
  final VoidCallback? onTap;

  const DailyRewardsButton({
    Key? key,
    this.compact = false,
    this.showCard = false,
    this.onTap,
  }) : super(key: key);

  /// Compact button with just icon and streak
  factory DailyRewardsButton.compact({VoidCallback? onTap}) {
    return DailyRewardsButton(compact: true, onTap: onTap);
  }

  /// Full card with streak info
  factory DailyRewardsButton.card({VoidCallback? onTap}) {
    return DailyRewardsButton(showCard: true, onTap: onTap);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(dailyRewardStatusProvider);

    if (showCard) {
      return _buildCard(context, ref, statusAsync);
    }

    if (compact) {
      return _buildCompact(context, ref, statusAsync);
    }

    return _buildButton(context, ref, statusAsync);
  }

  Widget _buildButton(BuildContext context, WidgetRef ref, AsyncValue statusAsync) {
    final canClaim = statusAsync.maybeWhen(
      data: (status) => status.canClaimToday,
      orElse: () => false,
    );

    final streak = statusAsync.maybeWhen(
      data: (status) => status.currentStreak,
      orElse: () => 0,
    );

    return ElevatedButton.icon(
      onPressed: () => _handleTap(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.card_giftcard),
          if (canClaim)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.notificationRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      label: Text(streak > 0 ? '🔥 $streak Day Streak' : 'Daily Reward'),
      style: ElevatedButton.styleFrom(
        backgroundColor: canClaim ? AppColors.accentPurple : null,
        foregroundColor: canClaim ? Colors.white : null,
      ),
    );
  }

  Widget _buildCompact(BuildContext context, WidgetRef ref, AsyncValue statusAsync) {
    final canClaim = statusAsync.maybeWhen(
      data: (status) => status.canClaimToday,
      orElse: () => false,
    );

    final streak = statusAsync.maybeWhen(
      data: (status) => status.currentStreak,
      orElse: () => 0,
    );

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: canClaim
              ? LinearGradient(
                  colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
                )
              : null,
          color: canClaim ? null : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 20,
                  color: canClaim ? Colors.white : Colors.grey,
                ),
                if (canClaim)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.notificationRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            if (streak > 0) ...[
              const SizedBox(width: 6),
              Text(
                '🔥$streak',
                style: TextStyle(
                  color: canClaim ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, AsyncValue statusAsync) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return statusAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        return GestureDetector(
          onTap: () => _handleTap(context),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              gradient: status.canClaimToday
                  ? LinearGradient(
                      colors: [
                        AppColors.accentPurple.withOpacity(0.2),
                        AppColors.accentGradientEnd.withOpacity(0.1),
                      ],
                    )
                  : null,
              color: status.canClaimToday ? null : surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: status.canClaimToday
                    ? AppColors.accentPurple
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Icon with notification dot
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(
                        child: Icon(Icons.card_giftcard, color: Colors.white),
                      ),
                      if (status.canClaimToday)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.notificationRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                '!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Rewards',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        status.canClaimToday
                            ? 'Claim your reward now!'
                            : status.currentStreak > 0
                                ? '🔥 ${status.currentStreak} day streak'
                                : 'Come back tomorrow',
                        style: AppTypography.caption.copyWith(
                          color: status.canClaimToday
                              ? AppColors.accentPurple
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: status.canClaimToday ? AppColors.accentPurple : Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      // Show dialog or navigate
      DailyRewardsDialog.show(context);
    }
  }
}

/// Floating action button for daily rewards
/// Use in scaffold's floatingActionButton
class DailyRewardsFAB extends ConsumerWidget {
  const DailyRewardsFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(dailyRewardStatusProvider);

    final canClaim = statusAsync.maybeWhen(
      data: (status) => status.canClaimToday,
      orElse: () => false,
    );

    if (!canClaim) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => DailyRewardsDialog.show(context),
      backgroundColor: AppColors.accentPurple,
      icon: const Icon(Icons.card_giftcard, color: Colors.white),
      label: const Text(
        'Claim Reward',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
