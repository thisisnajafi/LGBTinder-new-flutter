import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../providers/marketing_providers.dart';
import '../../data/models/daily_reward_model.dart';
import '../../data/services/daily_rewards_service.dart';

/// Daily rewards screen with full reward calendar and history
/// Part of the Marketing System Implementation (Task 3.5.2)
class DailyRewardsScreen extends ConsumerStatefulWidget {
  const DailyRewardsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends ConsumerState<DailyRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isClaiming = false;
  ClaimResult? _claimResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_isClaiming) return;

    setState(() => _isClaiming = true);

    try {
      final service = ref.read(dailyRewardsServiceProvider);
      final result = await service.claimReward();

      setState(() => _claimResult = result);

      // Refresh status
      ref.invalidate(dailyRewardStatusProvider);
      ref.invalidate(dailyRewardsConfigProvider);
    } catch (e) {
      setState(() {
        _claimResult = ClaimResult(
          success: false,
          message: 'Failed to claim reward',
        );
      });
    } finally {
      setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Daily Rewards',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
                ),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: textColor,
              tabs: const [
                Tab(text: 'Rewards'),
                Tab(text: 'Leaderboard'),
                Tab(text: 'History'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRewardsTab(),
                _buildLeaderboardTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    final statusAsync = ref.watch(dailyRewardStatusProvider);
    final configAsync = ref.watch(dailyRewardsConfigProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (status) => configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) => SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            children: [
              // Streak card
              _buildStreakCard(status),

              SizedBox(height: AppSpacing.spacingXL),

              // Reward calendar
              Text(
                '7-Day Reward Cycle',
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              _buildRewardCalendar(status, config),

              SizedBox(height: AppSpacing.spacingXL),

              // Claim button
              _buildClaimButton(status),

              // Result message
              if (_claimResult != null) ...[
                SizedBox(height: AppSpacing.spacingMD),
                _buildResultMessage(),
              ],

              SizedBox(height: AppSpacing.spacingXL),

              // Streak bonuses info
              _buildStreakBonusesInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(DailyRewardStatus status) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStreakStat('🔥', status.currentStreak.toString(), 'Current\nStreak'),
              Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
              _buildStreakStat('🏆', status.longestStreak.toString(), 'Best\nStreak'),
              Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
              _buildStreakStat('📅', status.currentDayInCycle.toString(), 'Day in\nCycle'),
            ],
          ),
          if (status.streakBonusPercentage != null && status.streakBonusPercentage! > 0) ...[
            SizedBox(height: AppSpacing.spacingLG),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingSM,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
              ),
              child: Text(
                '+${status.streakBonusPercentage!.toInt()}% Streak Bonus Active!',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        SizedBox(height: AppSpacing.spacingXS),
        Text(
          value,
          style: AppTypography.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRewardCalendar(DailyRewardStatus status, List<DailyRewardConfig> config) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final dayConfig = config.firstWhere(
          (c) => c.dayNumber == dayNumber,
          orElse: () => DailyRewardConfig(
            dayNumber: dayNumber,
            rewardType: 'coins',
            rewardAmount: dayNumber * 10,
          ),
        );

        final isClaimed = dayNumber < status.currentDayInCycle;
        final isToday = dayNumber == status.currentDayInCycle;

        return _buildDayCard(dayConfig, isClaimed, isToday);
      },
    );
  }

  Widget _buildDayCard(DailyRewardConfig config, bool isClaimed, bool isToday) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    Color borderColor;
    Color bgColor;
    if (isClaimed) {
      borderColor = AppColors.onlineGreen;
      bgColor = AppColors.onlineGreen.withOpacity(0.1);
    } else if (isToday) {
      borderColor = AppColors.accentPurple;
      bgColor = AppColors.accentPurple.withOpacity(0.1);
    } else {
      borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
      bgColor = surfaceColor;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Day ${config.dayNumber}',
            style: AppTypography.caption.copyWith(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(height: 4),
          Icon(
            isClaimed ? Icons.check_circle : _getRewardIcon(config.rewardType),
            color: isClaimed ? AppColors.onlineGreen : (isToday ? AppColors.accentPurple : Colors.grey),
            size: 20,
          ),
          SizedBox(height: 2),
          Text(
            '${config.rewardAmount}',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'superlikes':
        return Icons.star;
      case 'profile_views':
        return Icons.visibility;
      case 'boosts':
        return Icons.bolt;
      case 'premium_days':
        return Icons.diamond;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildClaimButton(DailyRewardStatus status) {
    final canClaim = status.canClaimToday && _claimResult == null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canClaim && !_isClaiming ? _claimReward : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canClaim ? AppColors.accentPurple : Colors.grey,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingLG),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          ),
        ),
        child: _isClaiming
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                canClaim
                    ? 'Claim Today\'s Reward 🎁'
                    : _claimResult != null
                        ? 'Claimed! ✓'
                        : 'Come Back Tomorrow',
                style: AppTypography.button.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildResultMessage() {
    final isSuccess = _claimResult?.success ?? false;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: (isSuccess ? AppColors.onlineGreen : AppColors.accentRed).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? AppColors.onlineGreen : AppColors.accentRed,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _claimResult?.message ?? '',
                  style: AppTypography.body.copyWith(
                    color: isSuccess ? AppColors.onlineGreen : AppColors.accentRed,
                  ),
                ),
                if (isSuccess && _claimResult?.rewardAmount != null)
                  Text(
                    '+${_claimResult!.rewardAmount} ${_claimResult!.rewardType}',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.onlineGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBonusesInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 Streak Bonuses',
            style: AppTypography.h4.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildBonusRow('3-day streak', '+10% bonus rewards'),
          _buildBonusRow('7-day streak', '+25% bonus rewards'),
          _buildBonusRow('14-day streak', '+50% bonus rewards'),
          _buildBonusRow('30-day streak', '+100% bonus rewards'),
        ],
      ),
    );
  }

  Widget _buildBonusRow(String streak, String bonus) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(streak, style: AppTypography.body),
          Text(
            bonus,
            style: AppTypography.body.copyWith(
              color: AppColors.onlineGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    final leaderboardAsync = ref.watch(dailyRewardsLeaderboardProvider);

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (leaderboard) => ListView.builder(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final entry = leaderboard[index];
          return _buildLeaderboardEntry(entry, index + 1);
        },
      ),
    );
  }

  Widget _buildLeaderboardEntry(StreakLeaderboardEntry entry, int rank) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    Color? rankColor;
    IconData? rankIcon;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.emoji_events;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: rankColor != null
            ? Border.all(color: rankColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor ?? Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: Colors.white, size: 20)
                  : Text(
                      '$rank',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${entry.currentStreak} day streak',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          // Streak flame
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              SizedBox(width: 4),
              Text(
                '${entry.longestStreak}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    // This would need a history provider - using placeholder for now
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: secondaryTextColor,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Claim History',
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          Text(
            'Your reward claim history will appear here',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
