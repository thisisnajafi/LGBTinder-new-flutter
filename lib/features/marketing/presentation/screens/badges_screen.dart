import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../providers/marketing_providers.dart';
import '../../data/models/badge_model.dart';
import '../../data/services/gamification_service.dart';
import '../widgets/badge_display.dart';
import '../widgets/badge_achievement_popup.dart';

/// Badges/Achievements screen
/// Part of the Marketing System Implementation (Task 3.5.3)
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Badges & Achievements',
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
                Tab(text: 'All'),
                Tab(text: 'Earned'),
                Tab(text: 'Leaderboard'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllBadgesTab(),
                _buildEarnedBadgesTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllBadgesTab() {
    final badgesAsync = ref.watch(allBadgesProvider);
    final eligibilityAsync = ref.watch(badgeEligibilityProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return badgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (badges) {
        // Get unique categories
        final categories = ['all', ...badges.map((b) => b.category ?? 'other').toSet()];

        // Filter by category
        final filteredBadges = _selectedCategory == 'all'
            ? badges
            : badges.where((b) => (b.category ?? 'other') == _selectedCategory).toList();

        // Separate earned and unearned
        final earnedBadges = filteredBadges.where((b) => b.isEarned).toList();
        final unearnedBadges = filteredBadges.where((b) => !b.isEarned).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats card
              _buildStatsCard(badges),

              SizedBox(height: AppSpacing.spacingLG),

              // Claim eligible badges button
              eligibilityAsync.maybeWhen(
                data: (eligibility) {
                  if (eligibility.eligibleBadges.isNotEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.spacingLG),
                      child: _buildClaimEligibleButton(eligibility),
                    );
                  }
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),

              // Category filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories.elementAt(index);
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: EdgeInsets.only(right: AppSpacing.spacingSM),
                      child: FilterChip(
                        label: Text(_formatCategory(category)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                        selectedColor: AppColors.accentPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: AppSpacing.spacingLG),

              // Earned section
              if (earnedBadges.isNotEmpty) ...[
                Text(
                  'Earned (${earnedBadges.length})',
                  style: AppTypography.h4.copyWith(color: textColor),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                BadgeGrid(
                  badges: earnedBadges,
                  onBadgeTap: (badge) => _showBadgeDetail(badge),
                ),
                SizedBox(height: AppSpacing.spacingXL),
              ],

              // Unearned section
              if (unearnedBadges.isNotEmpty) ...[
                Text(
                  'To Unlock (${unearnedBadges.length})',
                  style: AppTypography.h4.copyWith(color: textColor),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                BadgeGrid(
                  badges: unearnedBadges,
                  showProgress: true,
                  onBadgeTap: (badge) => _showBadgeDetail(badge),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(List<BadgeModel> badges) {
    final earnedCount = badges.where((b) => b.isEarned).length;
    final totalCount = badges.length;
    final progress = totalCount > 0 ? earnedCount / totalCount : 0.0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('🏆', earnedCount.toString(), 'Earned'),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
              _buildStatItem('🎯', totalCount.toString(), 'Total'),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
              _buildStatItem('⭐', '${(progress * 100).toInt()}%', 'Complete'),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildClaimEligibleButton(BadgeEligibility eligibility) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.onlineGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: AppColors.onlineGreen),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingSM),
            decoration: BoxDecoration(
              color: AppColors.onlineGreen,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${eligibility.eligibleBadges.length}',
              style: AppTypography.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New badges available!',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onlineGreen,
                  ),
                ),
                Text(
                  'Tap to claim your achievements',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _claimEligibleBadges(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onlineGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Claim'),
          ),
        ],
      ),
    );
  }

  Future<void> _claimEligibleBadges() async {
    try {
      final service = ref.read(gamificationServiceProvider);
      final result = await service.claimBadges();

      if (result.success && result.claimedBadges.isNotEmpty && mounted) {
        // Show achievement popup
        await MultipleBadgeAchievementPopup.show(context, result.claimedBadges);

        // Refresh badges
        ref.invalidate(allBadgesProvider);
        ref.invalidate(badgeEligibilityProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim badges: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildEarnedBadgesTab() {
    final badgesAsync = ref.watch(myBadgesProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return badgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (badges) {
        if (badges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 64, color: secondaryTextColor),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'No badges yet',
                  style: AppTypography.h3.copyWith(color: textColor),
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'Complete activities to earn badges!',
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display settings
              _buildDisplaySettings(badges),
              SizedBox(height: AppSpacing.spacingXL),

              // Earned badges
              BadgeGrid(
                badges: badges,
                onBadgeTap: (badge) => _showBadgeDetail(badge),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplaySettings(List<BadgeModel> badges) {
    final displayedAsync = ref.watch(displayedBadgesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Display',
            style: AppTypography.h4.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingSM),
          Text(
            'Select badges to show on your profile (max 3)',
            style: AppTypography.caption,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          displayedAsync.when(
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox.shrink(),
            data: (displayed) => BadgeRow(
              badges: displayed,
              maxDisplay: 3,
              badgeSize: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    final leaderboardAsync = ref.watch(badgeLeaderboardProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

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

  Widget _buildLeaderboardEntry(BadgeLeaderboardEntry entry, int rank) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    Color? rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: rankColor != null ? Border.all(color: rankColor, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor ?? Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rankColor != null ? Colors.white : textColor,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
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
                  '${entry.totalBadges} badges',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints}',
                style: AppTypography.h4.copyWith(
                  color: AppColors.accentPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'points',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BadgeModel badge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

          return Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              child: BadgeDetailCard(
                badge: badge,
                onClaimReward: badge.isEarned && !badge.rewardClaimed
                    ? () => _claimBadgeReward(badge)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _claimBadgeReward(BadgeModel badge) async {
    try {
      final service = ref.read(gamificationServiceProvider);
      final result = await service.claimReward(badge.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppColors.onlineGreen : AppColors.accentRed,
          ),
        );

        if (result.success) {
          ref.invalidate(myBadgesProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim reward: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  String _formatCategory(String category) {
    if (category == 'all') return 'All';
    return category.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
