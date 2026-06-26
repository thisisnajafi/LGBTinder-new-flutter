// Screen: ReportHistoryScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/error_handling/empty_state.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';

/// Report history screen - View report history
class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  ConsumerState<ReportHistoryScreen> createState() =>
      _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends ConsumerState<ReportHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.reports,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        final reportsData = data?['reports'] as Map<String, dynamic>?;
        final reportsList = reportsData?['data'] as List<dynamic>? ?? [];

        setState(() {
          _reports = reportsList.map((report) {
            final reportable = report['reportable'] as Map<String, dynamic>?;
            return {
              'id': report['id'],
              'user_name': reportable?['name'] ?? 'Unknown User',
              'reason': report['reason'] ?? 'No reason provided',
              'status': report['status'] ?? 'Unknown',
              'reported_at': DateTime.parse(report['created_at']),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _reports = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _reports = [];
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return AppColors.onlineGreen;
      case 'under review':
        return AppColors.feedbackWarning;
      case 'dismissed':
        return AppColors.textSecondaryDark;
      default:
        return AppColors.accentViolet;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Report history',
      subtitle: 'Reports you have submitted',
      action: IconButton(
        icon: AppSvgIcon(
          assetPath: AppIcons.getIconPath('refresh'),
          size: 22,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: _loadReports,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const EmptyState(
                  title: 'No reports',
                  message: 'You haven\'t reported any users yet',
                  iconPath: AppIcons.report,
                )
              : AppSettingsDetailList(
                  children: [
                    PremiumSettingsGroup(
                      title: 'Your reports',
                      subtitle: '${_reports.length} ${_reports.length == 1 ? 'report' : 'reports'}',
                      children: [
                        for (final report in _reports)
                          _ReportRow(
                            userName: report['user_name'] as String,
                            reason: report['reason'] as String,
                            status: report['status'] as String,
                            statusColor: _getStatusColor(report['status'] as String),
                            reportedLabel:
                                'Reported ${_formatTime(report['reported_at'] as DateTime)}',
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.userName,
    required this.reason,
    required this.status,
    required this.statusColor,
    required this.reportedLabel,
  });

  final String userName;
  final String reason;
  final String status;
  final Color statusColor;
  final String reportedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingSM,
                  vertical: AppSpacing.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          Row(
            children: [
              AppSvgIcon(
                assetPath: AppIcons.clock,
                size: 14,
                color: secondaryTextColor,
              ),
              const SizedBox(width: AppSpacing.spacingXS),
              Text(
                reportedLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
