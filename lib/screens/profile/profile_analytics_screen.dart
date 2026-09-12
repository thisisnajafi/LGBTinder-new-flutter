// Screen: ProfileAnalyticsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/loading/skeleton_loader.dart';

/// Profile analytics — lazy charts + isolated paint (PERF-SCR-ANALYTICS-001/002).
class ProfileAnalyticsScreen extends ConsumerStatefulWidget {
  const ProfileAnalyticsScreen({super.key});

  @override
  ConsumerState<ProfileAnalyticsScreen> createState() =>
      _ProfileAnalyticsScreenState();
}

class _ProfileAnalyticsScreenState
    extends ConsumerState<ProfileAnalyticsScreen> {
  bool _isLoading = true;
  String _selectedPeriod = 'week';

  int _totalProfileViews = 0;
  int _totalMatches = 0;
  int _totalLikes = 0;
  int _totalSuperlikes = 0;
  double _matchRate = 0;
  double _responseRate = 0;
  List<Map<String, dynamic>> _recentViews = const [];
  List<Map<String, dynamic>> _topInterests = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      setState(() {
        _totalProfileViews = 245;
        _totalMatches = 12;
        _totalLikes = 89;
        _totalSuperlikes = 5;
        _matchRate = 4.9;
        _responseRate = 78.5;
        _recentViews = [
          {
            'user_name': 'Alex',
            'viewed_at': DateTime.now().subtract(const Duration(hours: 2)),
          },
          {
            'user_name': 'Sam',
            'viewed_at': DateTime.now().subtract(const Duration(hours: 5)),
          },
        ];
        _topInterests = [
          {'name': 'Music', 'count': 45},
          {'name': 'Travel', 'count': 32},
          {'name': 'Sports', 'count': 28},
        ];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return AppPageScaffold(
      title: 'Profile Analytics',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
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
                _buildPeriodButton(
                    'Week', 'week', textColor, secondaryTextColor),
                _buildPeriodButton(
                    'Month', 'month', textColor, secondaryTextColor),
                _buildPeriodButton(
                    'Year', 'year', textColor, secondaryTextColor),
                _buildPeriodButton('All', 'all', textColor, secondaryTextColor),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          if (_isLoading)
            Column(
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
          else ...[
            const SectionHeader(
              title: 'Overview',
              iconPath: AppIcons.discover,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            RepaintBoundary(
              key: const ValueKey('analytics_overview_chart'),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: AppBreakpoints.value(
                  context,
                  phone: 2,
                  tablet: 3,
                  desktop: 4,
                ),
                crossAxisSpacing: AppSpacing.spacingMD,
                mainAxisSpacing: AppSpacing.spacingMD,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    title: 'Profile Views',
                    value: _totalProfileViews.toString(),
                    iconPath: AppIcons.eye,
                    color: AppColors.accentPurple,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                  _buildStatCard(
                    title: 'Matches',
                    value: _totalMatches.toString(),
                    iconPath: AppIcons.heart,
                    color: AppColors.notificationRed,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                  _buildStatCard(
                    title: 'Likes',
                    value: _totalLikes.toString(),
                    iconPath: AppIcons.like,
                    color: AppColors.onlineGreen,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                  _buildStatCard(
                    title: 'Superlikes',
                    value: _totalSuperlikes.toString(),
                    iconPath: AppIcons.star,
                    color: AppColors.warningYellow,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
            const DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),
            SectionHeader(
              title: 'Engagement',
              iconPath: AppIcons.arrowUp,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            RepaintBoundary(
              key: const ValueKey('analytics_engagement_chart'),
              child: Column(
                children: [
                  _buildMetricCard(
                    title: 'Match Rate',
                    value: '${_matchRate.toStringAsFixed(1)}%',
                    subtitle:
                        '$_totalMatches matches from $_totalProfileViews views',
                    iconPath: AppIcons.heart,
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
                    iconPath: AppIcons.message,
                    color: AppColors.onlineGreen,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
            const DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),
            SectionHeader(
              title: 'Recent Profile Views',
              iconPath: AppIcons.eye,
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
              ..._recentViews.map(
                (view) => _buildViewItem(
                  view: view,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
              ),
            const DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),
            const SectionHeader(
              title: 'Top Interests',
              iconPath: AppIcons.flash,
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
              RepaintBoundary(
                key: const ValueKey('analytics_interests_chart'),
                child: Column(
                  children: [
                    for (final interest in _topInterests)
                      _buildInterestItem(
                        interest: interest,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                      ),
                  ],
                ),
              ),
            SizedBox(height: AppSpacing.spacingXXL),
          ],
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
          setState(() => _selectedPeriod = value);
          _loadAnalytics();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: isSelected ? Colors.white : secondaryTextColor,
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
    required String iconPath,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(assetPath: iconPath, size: 32, color: color),
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
            style: AppTypography.caption.copyWith(color: secondaryTextColor),
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
    required String iconPath,
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
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Center(
              child: AppSvgIcon(assetPath: iconPath, size: 28, color: color),
            ),
          ),
          SizedBox(width: AppSpacing.spacingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
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
            backgroundColor: AppColors.accentPurple.withValues(alpha: 0.2),
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
          AppSvgIcon(
            assetPath: AppIcons.eye,
            size: 20,
            color: secondaryTextColor,
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
        ? (_topInterests
            .map((i) => i['count'] as int)
            .reduce((a, b) => a > b ? a : b))
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accentPurple,
              ),
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
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}
