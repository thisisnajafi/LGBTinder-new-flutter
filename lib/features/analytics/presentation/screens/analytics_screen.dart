import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../widgets/error_handling/error_display_widget.dart';
import '../widgets/analytics_card.dart';
import '../widgets/analytics_chart.dart';
import '../../providers/analytics_provider.dart';

/// Analytics screen - displays user analytics and insights
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load analytics on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Activity'),
            Tab(text: 'Insights'),
          ],
        ),
        actions: [
          // Period selector
          PopupMenuButton<int>(
            onSelected: (days) {
              ref.read(analyticsProvider.notifier).changePeriod(days);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingMD),
              child: Row(
                children: [
                  Text(
                    '${analyticsState.selectedPeriodDays ?? 30} days',
                    style: AppTypography.bodyMedium,
                  ),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(analyticsState),
          _buildActivityTab(analyticsState),
          _buildInsightsTab(analyticsState),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null) {
      return ErrorDisplayWidget(
        error: state.error!,
        onRetry: () => ref.read(analyticsProvider.notifier).loadAnalytics(),
      );
    }

    final analytics = state.analytics;
    if (analytics == null) {
      return const Center(child: Text('No analytics data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info section
          Text(
            'Your Activity',
            style: AppTypography.titleLarge,
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Key metrics cards
          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Total Likes',
                  value: analytics.matchingAnalytics.totalLikes.toString(),
                  icon: Icons.favorite,
                  iconColor: AppColors.feedbackError,
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: AnalyticsCard(
                  title: 'Matches',
                  value: analytics.matchingAnalytics.totalMatches.toString(),
                  icon: Icons.favorite_border,
                  iconColor: AppColors.feedbackSuccess,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingMD),

          Row(
            children: [
              Expanded(
                child: AnalyticsCard(
                  title: 'Messages',
                  value: analytics.communicationAnalytics.totalMessagesSent.toString(),
                  icon: Icons.message,
                  iconColor: AppColors.primaryLight,
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: AnalyticsCard(
                  title: 'Sessions',
                  value: analytics.engagementMetrics.totalSessions.toString(),
                  icon: Icons.access_time,
                  iconColor: AppColors.accentPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingLG),

          // Activity breakdown chart
          AnalyticsChart(
            title: 'Activity Breakdown',
            data: analytics.activityBreakdown,
            barColor: AppColors.primaryLight,
            subtitle: 'Your activity types over the selected period',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(AnalyticsState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    final analytics = state.analytics;
    if (analytics == null) {
      return const Center(child: Text('No activity data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Details',
            style: AppTypography.titleLarge,
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Real-time metrics
          if (analytics.realTimeMetrics.totalActivities > 0) ...[
            AnalyticsCard(
              title: 'Real-time Activity',
              value: analytics.realTimeMetrics.totalActivities.toString(),
              icon: Icons.trending_up,
              iconColor: AppColors.feedbackInfo,
              subtitle: 'Activities in your current session',
            ),
            SizedBox(height: AppSpacing.spacingMD),
          ],

          // Matching activity
          AnalyticsCard(
            title: 'Matching Activity',
            value: '${analytics.matchingAnalytics.totalLikes} likes, ${analytics.matchingAnalytics.totalMatches} matches',
            icon: Icons.favorite,
            iconColor: AppColors.feedbackError,
            subtitle: 'Your matching performance',
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Communication activity
          AnalyticsCard(
            title: 'Communication',
            value: '${analytics.communicationAnalytics.totalMessagesSent} sent, ${analytics.communicationAnalytics.totalMessagesReceived} received',
            icon: Icons.message,
            iconColor: AppColors.primaryLight,
            subtitle: 'Your messaging activity',
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Session activity
          AnalyticsCard(
            title: 'Session Time',
            value: '${(analytics.engagementMetrics.totalSessionDuration / 3600).round()}h ${(analytics.engagementMetrics.totalSessionDuration % 3600 / 60).round()}m',
            icon: Icons.access_time,
            iconColor: AppColors.accentPurple,
            subtitle: 'Total time spent in the app',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(AnalyticsState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    final analytics = state.analytics;
    if (analytics == null) {
      return const Center(child: Text('No insights data available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights & Trends',
            style: AppTypography.titleLarge,
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Engagement insights
          AnalyticsCard(
            title: 'Engagement Score',
            value: '${(analytics.engagementMetrics.retentionRate * 100).round()}%',
            icon: Icons.insights,
            iconColor: AppColors.feedbackSuccess,
            subtitle: 'Your app engagement level',
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Matching insights
          AnalyticsCard(
            title: 'Match Rate',
            value: '${(analytics.matchingAnalytics.matchRate * 100).round()}%',
            icon: Icons.trending_up,
            iconColor: analytics.matchingAnalytics.matchRate > 0.1
                ? AppColors.feedbackSuccess
                : AppColors.feedbackWarning,
            subtitle: 'Percentage of likes that became matches',
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Communication insights
          AnalyticsCard(
            title: 'Response Rate',
            value: '${(analytics.communicationAnalytics.responseRate * 100).round()}%',
            icon: Icons.reply,
            iconColor: analytics.communicationAnalytics.responseRate > 0.5
                ? AppColors.feedbackSuccess
                : AppColors.feedbackWarning,
            subtitle: 'How often you respond to messages',
          ),

          SizedBox(height: AppSpacing.spacingLG),

          // Activity trends chart
          if (analytics.matchingAnalytics.likesByDay.isNotEmpty)
            AnalyticsChart(
              title: 'Daily Activity Trend',
              data: analytics.matchingAnalytics.likesByDay,
              barColor: AppColors.primaryLight,
              subtitle: 'Your daily activity pattern',
            ),
        ],
      ),
    );
  }
}
