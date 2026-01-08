import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../data/models/subscription_plan.dart';

/// Widget to display subscription renewal reminders
/// Shows reminders when subscription is expiring soon (7, 3, 1 days)
class SubscriptionRenewalReminder extends StatelessWidget {
  final SubscriptionStatus subscriptionStatus;
  final VoidCallback? onManageSubscription;
  final VoidCallback? onCancelAutoRenewal;
  final VoidCallback? onChangePlan;

  const SubscriptionRenewalReminder({
    Key? key,
    required this.subscriptionStatus,
    this.onManageSubscription,
    this.onCancelAutoRenewal,
    this.onChangePlan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!subscriptionStatus.isActive || subscriptionStatus.endDate == null) {
      return const SizedBox.shrink();
    }

    final daysRemaining = _getDaysRemaining();
    if (daysRemaining == null || daysRemaining > 7) {
      return const SizedBox.shrink();
    }

    final reminderLevel = _getReminderLevel(daysRemaining);
    if (reminderLevel == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: EdgeInsets.all(AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: reminderLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: reminderLevel.color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                reminderLevel.icon,
                color: reminderLevel.color,
                size: 24,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Text(
                  reminderLevel.title,
                  style: AppTypography.h3.copyWith(
                    color: reminderLevel.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.spacingMD),

          // Message
          Text(
            reminderLevel.getMessage(daysRemaining, subscriptionStatus.endDate!),
            style: AppTypography.body.copyWith(
              color: textColor,
            ),
          ),

          if (subscriptionStatus.nextBillingDate != null) ...[
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Next billing: ${DateFormat('MMM d, y').format(subscriptionStatus.nextBillingDate!)}',
              style: AppTypography.caption.copyWith(
                color: secondaryTextColor,
              ),
            ),
          ],

          SizedBox(height: AppSpacing.spacingMD),

          // Actions
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: [
              if (onManageSubscription != null)
                OutlinedButton(
                  onPressed: onManageSubscription,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: reminderLevel.color,
                    side: BorderSide(color: reminderLevel.color),
                  ),
                  child: const Text('Manage'),
                ),
              if (onCancelAutoRenewal != null && subscriptionStatus.autoRenew)
                OutlinedButton(
                  onPressed: onCancelAutoRenewal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRed,
                    side: BorderSide(color: AppColors.accentRed),
                  ),
                  child: const Text('Cancel Auto-Renew'),
                ),
              if (onChangePlan != null)
                OutlinedButton(
                  onPressed: onChangePlan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentPurple,
                    side: BorderSide(color: AppColors.accentPurple),
                  ),
                  child: const Text('Change Plan'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  int? _getDaysRemaining() {
    if (subscriptionStatus.endDate == null) return null;
    final now = DateTime.now();
    final endDate = subscriptionStatus.endDate!;
    final difference = endDate.difference(now).inDays;
    return difference >= 0 ? difference : null;
  }

  ReminderLevel? _getReminderLevel(int daysRemaining) {
    if (daysRemaining <= 1) {
      return ReminderLevel.critical;
    } else if (daysRemaining <= 3) {
      return ReminderLevel.warning;
    } else if (daysRemaining <= 7) {
      return ReminderLevel.info;
    }
    return null;
  }
}

/// Reminder level configuration
class ReminderLevel {
  final String title;
  final Color color;
  final IconData icon;
  final String Function(int days, DateTime endDate) getMessage;

  const ReminderLevel._({
    required this.title,
    required this.color,
    required this.icon,
    required this.getMessage,
  });

  static const critical = ReminderLevel._(
    title: 'Subscription Expiring Soon!',
    color: AppColors.accentRed,
    icon: Icons.warning,
    getMessage: (days, endDate) {
      if (days == 0) {
        return 'Your subscription expires today. Renew now to continue enjoying premium features.';
      } else {
        return 'Your subscription expires in $days day${days == 1 ? '' : 's'}. Renew now to avoid interruption.';
      }
    },
  );

  static const warning = ReminderLevel._(
    title: 'Subscription Expiring in 3 Days',
    color: Colors.orange,
    icon: Icons.schedule,
    getMessage: (days, endDate) {
      return 'Your subscription will expire in $days days (${DateFormat('MMM d, y').format(endDate)}). Consider renewing to maintain access.';
    },
  );

  static const info = ReminderLevel._(
    title: 'Subscription Renewal Reminder',
    color: AppColors.accentYellow,
    icon: Icons.info_outline,
    getMessage: (days, endDate) {
      return 'Your subscription will renew in $days days (${DateFormat('MMM d, y').format(endDate)}).';
    },
  );
}
