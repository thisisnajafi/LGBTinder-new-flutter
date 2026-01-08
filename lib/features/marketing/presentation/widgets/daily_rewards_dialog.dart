import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/daily_reward_model.dart';
import '../../providers/marketing_providers.dart';
import '../../data/services/daily_rewards_service.dart';

/// Daily rewards dialog widget
/// Shows 7-day calendar with streak progress and claim button
/// Part of the Marketing System Implementation (Task 3.4.2)
class DailyRewardsDialog extends ConsumerStatefulWidget {
  const DailyRewardsDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DailyRewardsDialog(),
    );
  }

  @override
  ConsumerState<DailyRewardsDialog> createState() => _DailyRewardsDialogState();
}

class _DailyRewardsDialogState extends ConsumerState<DailyRewardsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isClaiming = false;
  ClaimResult? _claimResult;
  bool _showRewardAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_isClaiming) return;

    setState(() => _isClaiming = true);

    try {
      final service = ref.read(dailyRewardsServiceProvider);
      final result = await service.claimReward();

      setState(() {
        _claimResult = result;
        if (result.success) {
          _showRewardAnimation = true;
        }
      });

      // Refresh status
      ref.invalidate(dailyRewardStatusProvider);
    } catch (e) {
      setState(() {
        _claimResult = ClaimResult(
          success: false,
          message: 'Failed to claim reward. Please try again.',
        );
      });
    } finally {
      setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(dailyRewardStatusProvider);
    final configAsync = ref.watch(dailyRewardsConfigProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(theme),

                // Content
                statusAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Failed to load rewards',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.accentRed,
                      ),
                    ),
                  ),
                  data: (status) => configAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (config) => _buildContent(theme, status, config),
                  ),
                ),

                // Footer with claim button
                statusAsync.maybeWhen(
                  data: (status) => _buildFooter(theme, status),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple,
            AppColors.accentGradientEnd,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.card_giftcard,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Daily Rewards',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Claim your daily bonus!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    DailyRewardStatus status,
    List<DailyRewardConfig> config,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Streak indicator
          _buildStreakIndicator(theme, status),

          const SizedBox(height: 24),

          // 7-day calendar
          _buildCalendar(theme, status, config),

          // Claim result message
          if (_claimResult != null) ...[
            const SizedBox(height: 16),
            _buildResultMessage(theme),
          ],

          // Reward animation overlay
          if (_showRewardAnimation) _buildRewardAnimation(theme),
        ],
      ),
    );
  }

  Widget _buildStreakIndicator(ThemeData theme, DailyRewardStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentPurple.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStreakStat(
            theme,
            '🔥',
            status.currentStreak.toString(),
            'Current',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.accentPurple.withOpacity(0.3),
          ),
          _buildStreakStat(
            theme,
            '🏆',
            status.longestStreak.toString(),
            'Best',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.accentPurple.withOpacity(0.3),
          ),
          _buildStreakStat(
            theme,
            '📅',
            'Day ${status.currentDayInCycle}',
            'Cycle',
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(
    ThemeData theme,
    String emoji,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.accentPurple,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
    ThemeData theme,
    DailyRewardStatus status,
    List<DailyRewardConfig> config,
  ) {
    // Build 7 days
    final days = List.generate(7, (index) {
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
      final isFuture = dayNumber > status.currentDayInCycle;

      return _buildDayCard(theme, dayConfig, isClaimed, isToday, isFuture);
    });

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: days,
    );
  }

  Widget _buildDayCard(
    ThemeData theme,
    DailyRewardConfig config,
    bool isClaimed,
    bool isToday,
    bool isFuture,
  ) {
    final iconData = _getRewardIcon(config.rewardType);
    final color = isClaimed
        ? AppColors.onlineGreen
        : isToday
            ? AppColors.accentPurple
            : theme.colorScheme.onSurface.withOpacity(0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.accentPurple.withOpacity(0.1)
            : isClaimed
                ? AppColors.onlineGreen.withOpacity(0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.accentPurple
              : isClaimed
                  ? AppColors.onlineGreen
                  : theme.colorScheme.outline.withOpacity(0.2),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Day ${config.dayNumber}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            isClaimed ? Icons.check_circle : iconData,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            _getRewardLabel(config),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
      case 'combo':
        return Icons.card_giftcard;
      default:
        return Icons.monetization_on;
    }
  }

  String _getRewardLabel(DailyRewardConfig config) {
    switch (config.rewardType) {
      case 'superlikes':
        return '${config.rewardAmount} Super';
      case 'profile_views':
        return '${config.rewardAmount} Views';
      case 'boosts':
        return '${config.rewardAmount} Boost';
      case 'premium_days':
        return '${config.rewardAmount}d Free';
      case 'combo':
        return 'Combo!';
      default:
        return '${config.rewardAmount}';
    }
  }

  Widget _buildResultMessage(ThemeData theme) {
    final isSuccess = _claimResult?.success ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isSuccess ? AppColors.onlineGreen : AppColors.accentRed)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? AppColors.onlineGreen : AppColors.accentRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _claimResult?.message ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSuccess ? AppColors.onlineGreen : AppColors.accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardAnimation(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: 1 - value,
          child: Transform.translate(
            offset: Offset(0, -50 * value),
            child: Text(
              '+${_claimResult?.rewardAmount ?? 0} ${_claimResult?.rewardType ?? ''}!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.onlineGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        setState(() => _showRewardAnimation = false);
      },
    );
  }

  Widget _buildFooter(ThemeData theme, DailyRewardStatus status) {
    final canClaim = status.canClaimToday && _claimResult == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canClaim && !_isClaiming ? _claimReward : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canClaim
                    ? AppColors.accentPurple
                    : theme.colorScheme.outline,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                          ? 'Claim Reward 🎁'
                          : _claimResult != null
                              ? 'Claimed! ✓'
                              : 'Come Back Tomorrow',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
