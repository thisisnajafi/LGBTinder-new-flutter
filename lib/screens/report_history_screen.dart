// Screen: ReportHistoryScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/error_handling/empty_state.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';

/// Report history screen - View report history
class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
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
        return AppColors.warningYellow;
      case 'dismissed':
        return AppColors.textSecondaryDark;
      default:
        return AppColors.accentPurple;
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
        title: 'Report History',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? EmptyState(
                  title: 'No Reports',
                  message: 'You haven\'t reported any users yet',
                  icon: Icons.report,
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final statusColor = _getStatusColor(report['status']);
                    return Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                      padding: EdgeInsets.all(AppSpacing.spacingLG),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report['user_name'],
                                      style: AppTypography.h3.copyWith(
                                        color: textColor,
                                      ),
                                    ),
                                    SizedBox(height: AppSpacing.spacingXS),
                                    Text(
                                      report['reason'],
                                      style: AppTypography.body.copyWith(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.spacingSM,
                                  vertical: AppSpacing.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                ),
                                child: Text(
                                  report['status'],
                                  style: AppTypography.caption.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.spacingMD),
                          DividerCustom(),
                          SizedBox(height: AppSpacing.spacingSM),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: secondaryTextColor,
                              ),
                              SizedBox(width: AppSpacing.spacingXS),
                              Text(
                                'Reported ${_formatTime(report['reported_at'])}',
                                style: AppTypography.caption.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
