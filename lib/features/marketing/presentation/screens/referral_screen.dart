import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';

/// Enhanced referral screen with tier progress, milestones, and leaderboard.
/// Loads code, stats, history, and tiers from ReferralApiService (GET referrals/code, stats, history, tiers).
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // From API (GET referrals/code, stats, history, tiers); fallback to defaults on error
  String _referralCode = '—';
  int _totalReferrals = 0;
  int _pendingReferrals = 0;
  int _completedReferrals = 0;
  int _earnedCredits = 0;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _tiers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(referralApiServiceProvider);
      final codeRes = await service.getCode();
      final statsRes = await service.getStats();
      final historyRes = await service.getHistory();
      final tiersRes = await service.getTiers();

      final dataCode = codeRes['data'] ?? codeRes;
      final dataStats = statsRes['data'] ?? statsRes;
      final dataHistory = historyRes['data'] ?? historyRes;
      final dataTiers = tiersRes['data'] ?? tiersRes;

      String code = dataCode['code']?.toString() ?? dataCode['referral_code']?.toString() ?? '—';
      int total = _parseInt(dataStats['total_referrals'] ?? dataStats['total']) ?? 0;
      int pending = _parseInt(dataStats['pending_referrals'] ?? dataStats['pending']) ?? 0;
      int completed = _parseInt(dataStats['completed_referrals'] ?? dataStats['completed']) ?? 0;
      int credits = _parseInt(dataStats['earned_credits'] ?? dataStats['credits']) ?? 0;

      List<Map<String, dynamic>> history = [];
      if (dataHistory is List) {
        for (final e in dataHistory) {
          if (e is Map) history.add(Map<String, dynamic>.from(e));
        }
      } else if (dataHistory is Map && dataHistory['referrals'] is List) {
        for (final e in dataHistory['referrals'] as List) {
          if (e is Map) history.add(Map<String, dynamic>.from(e));
        }
      }

      List<Map<String, dynamic>> tiers = [];
      if (dataTiers is List) {
        for (final e in dataTiers) {
          if (e is Map) tiers.add(Map<String, dynamic>.from(e));
        }
      }

      if (mounted) {
        setState(() {
          _referralCode = code;
          _totalReferrals = total;
          _pendingReferrals = pending;
          _completedReferrals = completed;
          _earnedCredits = credits;
          _history = history;
          _tiers = tiers;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        });
      }
    }
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
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
        title: 'Invite Friends',
        showBackButton: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : Column(
        children: [
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accentYellow, size: 20),
                  SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(color: textColor),
                    ),
                  ),
                  TextButton(
                    onPressed: _load,
                    child: Text('Retry', style: AppTypography.labelMedium.copyWith(color: AppColors.accentPurple)),
                  ),
                ],
              ),
            ),
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
                Tab(text: 'Invite'),
                Tab(text: 'Milestones'),
                Tab(text: 'Leaderboard'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInviteTab(),
                _buildMilestonesTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accentPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          children: [
            // Stats card
            _buildStatsCard(),

          SizedBox(height: AppSpacing.spacingXL),

          // Tier progress
          _buildTierProgress(),

          SizedBox(height: AppSpacing.spacingXL),

          // Referral code section
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusLG),
            ),
            child: Column(
              children: [
                Text(
                  'Your Referral Code',
                  style: AppTypography.h4.copyWith(color: textColor),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingXL,
                    vertical: AppSpacing.spacingMD,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(color: AppColors.accentPurple),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _referralCode,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(width: AppSpacing.spacingMD),
                      IconButton(
                        onPressed: () => _copyCode(),
                        icon: const Icon(Icons.copy, color: AppColors.accentPurple),
                        tooltip: 'Copy code',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingLG),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareCode,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.spacingMD),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _inviteContacts,
                        icon: const Icon(Icons.contacts),
                        label: const Text('Contacts'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentPurple,
                          side: const BorderSide(color: AppColors.accentPurple),
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.spacingXL),

          // How it works
          _buildHowItWorks(),

          SizedBox(height: AppSpacing.spacingXL),

          // Recent referrals
          _buildRecentReferrals(),
        ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('👥', '$_totalReferrals', 'Total'),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('⏳', '$_pendingReferrals', 'Pending'),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('✅', '$_completedReferrals', 'Completed'),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('💎', '$_earnedCredits', 'Credits'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTierProgress() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    // Tier thresholds
    final tiers = [
      {'name': 'Starter', 'min': 0, 'color': Colors.grey},
      {'name': 'Bronze', 'min': 3, 'color': const Color(0xFFCD7F32)},
      {'name': 'Silver', 'min': 10, 'color': const Color(0xFFC0C0C0)},
      {'name': 'Gold', 'min': 25, 'color': const Color(0xFFFFD700)},
      {'name': 'Ambassador', 'min': 50, 'color': AppColors.accentPurple},
    ];

    // Find current tier
    int currentTierIndex = 0;
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (_completedReferrals >= (tiers[i]['min'] as int)) {
        currentTierIndex = i;
        break;
      }
    }

    final currentTier = tiers[currentTierIndex];
    final nextTier = currentTierIndex < tiers.length - 1 ? tiers[currentTierIndex + 1] : null;

    double progress = 1.0;
    int remaining = 0;
    if (nextTier != null) {
      final currentMin = currentTier['min'] as int;
      final nextMin = nextTier['min'] as int;
      progress = (_completedReferrals - currentMin) / (nextMin - currentMin);
      remaining = nextMin - _completedReferrals;
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Tier',
                    style: AppTypography.caption.copyWith(color: textColor),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: currentTier['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        currentTier['name'] as String,
                        style: AppTypography.h4.copyWith(
                          color: currentTier['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (nextTier != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Next Tier',
                      style: AppTypography.caption.copyWith(color: textColor),
                    ),
                    Row(
                      children: [
                        Text(
                          nextTier['name'] as String,
                          style: AppTypography.body.copyWith(
                            color: nextTier['color'] as Color,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: nextTier['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(currentTier['color'] as Color),
              minHeight: 8,
            ),
          ),
          if (nextTier != null) ...[
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              '$remaining more referrals to ${nextTier['name']}',
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: AppTypography.h4.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildStep(1, 'Share your code', 'Send your unique code to friends'),
          _buildStep(2, 'Friend signs up', 'They use your code during registration'),
          _buildStep(3, 'Both get rewarded', 'You each get 30 credits!'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReferrals() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Referrals',
            style: AppTypography.h4.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          if (_history.isEmpty)
            Text(
              'No referrals yet. Share your code to get started!',
              style: AppTypography.body.copyWith(color: textColor.withOpacity(0.7)),
            )
          else
            ..._history.take(10).map((r) => _buildReferralItemFromMap(r)),
        ],
      ),
    );
  }

  Widget _buildReferralItemFromMap(Map<String, dynamic> referral) {
    final name = referral['name']?.toString() ?? referral['referred_user_name']?.toString() ?? referral['email']?.toString() ?? '—';
    final displayName = name.length > 1 ? name[0].toUpperCase() + name.substring(1) : name;
    final status = referral['status']?.toString().toLowerCase() ?? 'pending';
    final isCompleted = status == 'completed' || status == 'converted';
    final date = referral['date']?.toString() ?? referral['created_at']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.withOpacity(0.3),
            child: Text(
              displayName.isNotEmpty ? displayName[0] : '?',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppTypography.body),
                if (date.isNotEmpty) Text(date, style: AppTypography.caption),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isCompleted ? AppColors.onlineGreen : AppColors.accentYellow).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompleted ? 'Completed' : 'Pending',
              style: AppTypography.caption.copyWith(
                color: isCompleted ? AppColors.onlineGreen : AppColors.accentYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralItem(Map<String, String> referral) {
    final isCompleted = referral['status'] == 'completed';
    final name = referral['name'] ?? '—';
    final date = referral['date'] ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.withOpacity(0.3),
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.body),
                Text(date, style: AppTypography.caption),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isCompleted ? AppColors.onlineGreen : AppColors.accentYellow).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompleted ? 'Completed' : 'Pending',
              style: AppTypography.caption.copyWith(
                color: isCompleted ? AppColors.onlineGreen : AppColors.accentYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final milestones = [
      {'count': 1, 'reward': '10 Credits', 'claimed': true},
      {'count': 3, 'reward': '30 Credits + Bronze Badge', 'claimed': true},
      {'count': 5, 'reward': '50 Credits', 'claimed': true},
      {'count': 10, 'reward': '100 Credits + Silver Badge', 'claimed': false},
      {'count': 25, 'reward': '250 Credits + Gold Badge', 'claimed': false},
      {'count': 50, 'reward': '500 Credits + Ambassador Status', 'claimed': false},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        final count = milestone['count'] as int;
        final isAchieved = _completedReferrals >= count;
        final isClaimed = milestone['claimed'] as bool;

        return Container(
          margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(
              color: isAchieved ? AppColors.onlineGreen : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAchieved
                      ? AppColors.onlineGreen.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isAchieved
                      ? const Icon(Icons.check, color: AppColors.onlineGreen)
                      : Text(
                          '$count',
                          style: AppTypography.h4.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
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
                      '$count Referrals',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      milestone['reward'] as String,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (isAchieved && !isClaimed)
                ElevatedButton(
                  onPressed: () => _claimMilestone(count),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onlineGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                  ),
                  child: const Text('Claim'),
                )
              else if (isClaimed)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.onlineGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Claimed ✓',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onlineGreen,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    // Mock leaderboard data
    final leaderboard = [
      {'name': 'Taylor S.', 'referrals': 127, 'tier': 'Ambassador'},
      {'name': 'Jordan M.', 'referrals': 89, 'tier': 'Ambassador'},
      {'name': 'Casey R.', 'referrals': 56, 'tier': 'Ambassador'},
      {'name': 'Riley K.', 'referrals': 34, 'tier': 'Gold'},
      {'name': 'Morgan P.', 'referrals': 28, 'tier': 'Gold'},
    ];

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        final rank = index + 1;

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
                  child: rank <= 3
                      ? Icon(Icons.emoji_events, color: Colors.white, size: 20)
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['name'] as String,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      entry['tier'] as String,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry['referrals']}',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'referrals',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied!'),
        backgroundColor: AppColors.onlineGreen,
      ),
    );
  }

  void _shareCode() {
    Share.share(
      'Join me on LGBTFinder! Use my referral code $_referralCode to get 30 free credits. Download now: https://lgbtfinder.app/download',
      subject: 'Join LGBTFinder!',
    );
  }

  void _inviteContacts() {
    // Would open contacts picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact picker coming soon!'),
      ),
    );
  }

  Future<void> _claimMilestone(int count) async {
    try {
      final service = ref.read(referralApiServiceProvider);
      await service.processMilestone();
      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone claimed!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not claim: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}'),
          ),
        );
      }
    }
  }
}
