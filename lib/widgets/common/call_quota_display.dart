import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../features/calls/providers/call_provider.dart';
import '../../features/calls/data/models/call_quota.dart';
import '../../shared/models/api_error.dart';
import '../../shared/services/error_handler_service.dart';

/// Widget to display user's call quota and usage
class CallQuotaDisplay extends ConsumerStatefulWidget {
  const CallQuotaDisplay({Key? key}) : super(key: key);

  @override
  ConsumerState<CallQuotaDisplay> createState() => _CallQuotaDisplayState();
}

class _CallQuotaDisplayState extends ConsumerState<CallQuotaDisplay> {
  CallQuota? _quota;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuota();
  }

  Future<void> _loadQuota() async {
    try {
      final callProviderInstance = ref.read(callProvider);
      final quota = await callProviderInstance.getCallQuota();

      if (mounted) {
        setState(() {
          _quota = quota;
          _isLoading = false;
        });
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to load call quota',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load call quota: $e'),
            backgroundColor: AppColors.notificationRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_quota == null) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
        ),
        child: Text(
          'Unable to load call quota',
          style: AppTypography.bodyMedium.copyWith(color: secondaryTextColor),
        ),
      );
    }

    final usedMinutes = _quota!.usedMinutes;
    final totalMinutes = _quota!.totalMinutes;
    final remainingMinutes = totalMinutes - usedMinutes;
    final usagePercentage = totalMinutes > 0 ? (usedMinutes / totalMinutes) : 0.0;

    // Determine color based on usage
    Color progressColor;
    if (usagePercentage >= 0.9) {
      progressColor = AppColors.notificationRed;
    } else if (usagePercentage >= 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppColors.onlineGreen;
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Call Minutes',
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$remainingMinutes remaining',
                style: AppTypography.bodySmall.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingSM),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: usagePercentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.spacingXS),

          // Usage text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used: ${usedMinutes}min',
                style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
              ),
              Text(
                'Total: ${totalMinutes}min',
                style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
              ),
            ],
          ),

          // Reset info
          if (_quota!.resetsAt != null) ...[
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Resets ${_formatResetTime(_quota!.resetsAt!)}',
              style: AppTypography.bodySmall.copyWith(
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatResetTime(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'soon';
    }
  }
}
