import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../models/subscription_plan.dart';

/// Subscription status card widget
/// Displays current subscription status and details
class SubscriptionStatusCard extends ConsumerWidget {
  final SubscriptionStatus subscriptionStatus;
  final VoidCallback? onManageSubscription;
  final VoidCallback? onUpgrade;
  final VoidCallback? onCancel;

  const SubscriptionStatusCard({
    Key? key,
    required this.subscriptionStatus,
    this.onManageSubscription,
    this.onUpgrade,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: subscriptionStatus.isActive
              ? LinearGradient(
                  colors: [
                    AppColors.primaryLight.withOpacity(0.1),
                    AppColors.secondaryLight.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 16,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (subscriptionStatus.isActive) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: AppSvgIcon(
                        assetPath: AppIcons.crown,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // Plan name
              if (subscriptionStatus.planName != null) ...[
                Text(
                  subscriptionStatus.planName!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Status details
              if (subscriptionStatus.isActive) ...[
                _buildDetailRow(
                  context,
                  'Active since',
                  subscriptionStatus.startDate != null
                      ? DateFormat('MMM d, yyyy').format(subscriptionStatus.startDate!)
                      : 'N/A',
                ),
                if (subscriptionStatus.nextBillingDate != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Next billing',
                    DateFormat('MMM d, yyyy').format(subscriptionStatus.nextBillingDate!),
                  ),
                ],
                if (subscriptionStatus.endDate != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Expires',
                    DateFormat('MMM d, yyyy').format(subscriptionStatus.endDate!),
                  ),
                ],
              ] else ...[
                Text(
                  'No active subscription',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  if (subscriptionStatus.isActive) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onManageSubscription,
                        icon: AppSvgIcon(
                          assetPath: AppIcons.settings,
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        label: const Text('Manage'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryLight),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onUpgrade,
                        icon: AppSvgIcon(
                          assetPath: AppIcons.arrowUp,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text('Upgrade'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onUpgrade,
                        icon: AppSvgIcon(
                          assetPath: AppIcons.crown,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text('Subscribe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              if (subscriptionStatus.isActive && subscriptionStatus.autoRenew) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: onCancel,
                    icon: AppSvgIcon(
                      assetPath: AppIcons.close,
                      size: 16,
                      color: AppColors.feedbackError,
                    ),
                    label: Text(
                      'Cancel Subscription',
                      style: TextStyle(color: AppColors.feedbackError),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (subscriptionStatus.status?.toLowerCase()) {
      case 'active':
        return AppColors.feedbackSuccess;
      case 'canceled':
      case 'expired':
        return AppColors.feedbackError;
      case 'trial':
        return AppColors.feedbackWarning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (subscriptionStatus.status?.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      case 'trial':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    return subscriptionStatus.status?.toUpperCase() ?? 'UNKNOWN';
  }
}
