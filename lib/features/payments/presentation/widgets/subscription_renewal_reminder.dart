import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_grouped_list_card.dart';
import '../../../../core/widgets/app_settings_detail.dart';
import '../../data/models/subscription_plan.dart';

/// Renewal notice shown inside a settings-style grouped section.
class SubscriptionRenewalReminder extends StatelessWidget {
  final SubscriptionStatus subscriptionStatus;
  final VoidCallback? onManageSubscription;
  final VoidCallback? onCancelAutoRenewal;
  final VoidCallback? onChangePlan;

  const SubscriptionRenewalReminder({
    super.key,
    required this.subscriptionStatus,
    this.onManageSubscription,
    this.onCancelAutoRenewal,
    this.onChangePlan,
  });

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
    final message = reminderLevel.getMessage(
      daysRemaining,
      subscriptionStatus.endDate!,
    );

    final actionEntries = <({String icon, String label, String? subtitle, VoidCallback onTap})>[];
    if (onChangePlan != null) {
      actionEntries.add((
        icon: AppIcons.crown,
        label: 'Change plan',
        subtitle: 'Compare plans and billing options',
        onTap: onChangePlan!,
      ));
    }
    if (onCancelAutoRenewal != null && subscriptionStatus.autoRenew) {
      actionEntries.add((
        icon: AppIcons.close,
        label: 'Cancel auto-renew',
        subtitle: 'Keep access until the end of your billing period',
        onTap: onCancelAutoRenewal!,
      ));
    }
    if (onManageSubscription != null) {
      actionEntries.add((
        icon: AppIcons.setting,
        label: 'Manage subscription',
        subtitle: null,
        onTap: onManageSubscription!,
      ));
    }

    final tiles = <Widget>[
      Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.spacingMD,
          AppSpacing.spacingMD,
          AppSpacing.spacingMD,
          actionEntries.isEmpty ? AppSpacing.spacingMD : AppSpacing.spacingSM,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSvgIcon(
              assetPath: reminderLevel.iconPath,
              size: 20,
              color: reminderLevel.color,
            ),
            const SizedBox(width: AppSpacing.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                  if (subscriptionStatus.nextBillingDate != null) ...[
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      'Next billing: ${DateFormat('MMM d, y').format(subscriptionStatus.nextBillingDate!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    for (var i = 0; i < actionEntries.length; i++) {
      final entry = actionEntries[i];
      tiles.add(
        AppGroupedListTile(
          iconPath: entry.icon,
          label: entry.label,
          subtitle: entry.subtitle,
          onTap: entry.onTap,
          showDivider: i < actionEntries.length - 1,
        ),
      );
    }

    return AppGroupedListSection(
      title: reminderLevel.title,
      padding: AppSettingsLayout.sectionPadding,
      children: tiles,
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

class ReminderLevel {
  final String title;
  final Color color;
  final String iconPath;
  final String Function(int days, DateTime endDate) getMessage;

  const ReminderLevel._({
    required this.title,
    required this.color,
    required this.iconPath,
    required this.getMessage,
  });

  static ReminderLevel get critical => ReminderLevel._(
        title: 'Expiring Soon',
        color: AppColors.feedbackError,
        iconPath: AppIcons.warning,
        getMessage: (days, endDate) {
          if (days == 0) {
            return 'Your subscription expires today. Renew now to continue enjoying premium features.';
          }
          return 'Your subscription expires in $days day${days == 1 ? '' : 's'}. Renew now to avoid interruption.';
        },
      );

  static ReminderLevel get warning => ReminderLevel._(
        title: 'Expiring In 3 Days',
        color: AppColors.feedbackWarning,
        iconPath: AppIcons.timerStart,
        getMessage: (days, endDate) {
          return 'Your subscription will expire in $days days (${DateFormat('MMM d, y').format(endDate)}). Consider renewing to maintain access.';
        },
      );

  static ReminderLevel get info => ReminderLevel._(
        title: 'Renewal Reminder',
        color: AppColors.feedbackWarning,
        iconPath: AppIcons.infoCircle,
        getMessage: (days, endDate) {
          return 'Your subscription will renew in $days days (${DateFormat('MMM d, y').format(endDate)}).';
        },
      );
}
