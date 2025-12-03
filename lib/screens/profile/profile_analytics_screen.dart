// Screen: ProfileAnalyticsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/loading/skeleton_loader.dart';

/// Profile analytics screen - Display profile views, match stats, engagement metrics
class ProfileAnalyticsScreen extends ConsumerStatefulWidget {
  const ProfileAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileAnalyticsScreen> createState() => _ProfileAnalyticsScreenState();
}

class _ProfileAnalyticsScreenState extends ConsumerState<ProfileAnalyticsScreen> {
  bool _isLoading = false;
  String _selectedPeriod = 'week'; // 'day', 'week', 'month', 'year', 'all'

  // Analytics data
  int _totalProfileViews = 0;
  int _totalMatches = 0;
  int _totalLikes = 0;
  int _totalSuperlikes = 0;
  int _totalMessages = 0;
  double _matchRate = 0.0; // percentage
  double _responseRate = 0.0; // percentage
  List<Map<String, dynamic>> _recentViews = [];
  List<Map<String, dynamic>> _topInterests = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load analytics from API
      // GET /api/profile/analytics?period={period}
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _totalProfileViews = 245;
          _totalMatches = 12;
          _totalLikes = 89;
          _totalSuperlikes = 5;
          _totalMessages = 156;
          _matchRate = 4.9; // 12 matches / 245 views
          _responseRate = 78.5; // percentage
          _recentViews = [
            {
              'user_id': 1,
              'user_name': 'Alex',
              'user_avatar': null,
              'viewed_at': DateTime.now().subtract(const Duration(hours: 2)),
            },
            {
              'user_id': 2,
              'user_name': 'Sam',
              'user_avatar': null,
              'viewed_at': DateTime.now().subtract(const Duration(hours: 5)),
            },
          ];
          _topInterests = [
            {'name': 'Music', 'count': 45},
            {'name': 'Travel', 'count': 32},
            {'name': 'Sports', 'count': 28},
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Profile Analytics',
        showBackButton: true,
      ),
      body: _isLoading
          ? ListView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 200,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                ),
                SizedBox(height: AppSpacing.spacingMD),
                SkeletonLoader(
                  width: double.infinity,
                  height: 150,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                ),
              ],
            )
          : ListView(
              padding: EdgeInsets.all(AppSpacing.spacingLG),
              children: [
                // Period selector
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingSM),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPeriodButton('Day', 'day', textColor, secondaryTextColor),
                      _buildPeriodButton('Week', 'week', textColor, secondaryTextColor),
                      _buildPeriodButton('Month', 'month', textColor, secondaryTextColor),
                      _buildPeriodButton('Year', 'year', textColor, secondaryTextColor),
                      _buildPeriodButton('All', 'all', textColor, secondaryTextColor),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.spacingLG),

                // Overview stats
                SectionHeader(
                  title: 'Overview',
                  icon: Icons.analytics,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.spacingMD,
                  mainAxisSpacing: AppSpacing.spacingMD,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      title: 'Profile Views',
                      value: _totalProfileViews.toString(),
                      icon: Icons.visibility,
                      color: AppColors.accentPurple,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                    _buildStatCard(
                      title: 'Matches',
                      value: _totalMatches.toString(),
                      icon: Icons.favorite,
                      color: AppColors.notificationRed,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                    _buildStatCard(
                      title: 'Likes',
                      value: _totalLikes.toString(),
                      icon: Icons.thumb_up,
                      color: AppColors.onlineGreen,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                    _buildStatCard(
                      title: 'Superlikes',
                      value: _totalSuperlikes.toString(),
                      icon: Icons.star,
                      color: AppColors.warningYellow,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                DividerCustom(),
                SizedBox(height: AppSpacing.spacingLG),

                // Engagement metrics
                SectionHeader(
                  title: 'Engagement',
                  icon: Icons.trending_up,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                _buildMetricCard(
                  title: 'Match Rate',
                  value: '${_matchRate.toStringAsFixed(1)}%',
                  subtitle: '${_totalMatches} matches from ${_totalProfileViews} views',
                  icon: Icons.favorite,
                  color: AppColors.accentPurple,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                _buildMetricCard(
                  title: 'Response Rate',
                  value: '${_responseRate.toStringAsFixed(1)}%',
                  subtitle: 'Message response rate',
                  icon: Icons.chat_bubble,
                  color: AppColors.onlineGreen,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
                DividerCustom(),
                SizedBox(height: AppSpacing.spacingLG),

                // Recent views
                SectionHeader(
                  title: 'Recent Profile Views',
                  icon: Icons.visibility,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                if (_recentViews.isEmpty)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingXL),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'No recent views',
                        style: AppTypography.body.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                else
                  ..._recentViews.map((view) {
                    return _buildViewItem(
                      view: view,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    );
                  }),
                DividerCustom(),
                SizedBox(height: AppSpacing.spacingLG),

                // Top interests
                SectionHeader(
                  title: 'Top Interests',
                  icon: Icons.local_fire_department,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                if (_topInterests.isEmpty)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingXL),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'No interest data',
                        style: AppTypography.body.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                else
                  ..._topInterests.map((interest) {
                    return _buildInterestItem(
                      interest: interest,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                    );
                  }),
                SizedBox(height: AppSpacing.spacingXXL),
              ],
            ),
    );
  }

  Widget _buildPeriodButton(
    String label,
    String value,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
          _loadAnalytics();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentPurple
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: isSelected
                  ? Colors.white
                  : secondaryTextColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            value,
            style: AppTypography.h1.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.spacingXS),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(width: AppSpacing.spacingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  value,
                  style: AppTypography.h2.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewItem({
    required Map<String, dynamic> view,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final viewedAt = view['viewed_at'] as DateTime;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingSM),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accentPurple.withOpacity(0.2),
            child: Text(
              (view['user_name'] as String? ?? 'U')[0].toUpperCase(),
              style: AppTypography.body.copyWith(
                color: AppColors.accentPurple,
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
                  view['user_name'] ?? 'User',
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  _formatTime(viewedAt),
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.visibility,
            color: secondaryTextColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestItem({
    required Map<String, dynamic> interest,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    final count = interest['count'] as int;
    final maxCount = _topInterests.isNotEmpty
        ? (_topInterests.map((i) => i['count'] as int).reduce((a, b) => a > b ? a : b))
        : 1;
    final percentage = (count / maxCount * 100).clamp(0.0, 100.0);

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingSM),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                interest['name'] ?? '',
                style: AppTypography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count',
                style: AppTypography.body.copyWith(
                  color: AppColors.accentPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
