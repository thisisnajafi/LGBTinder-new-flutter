// Widget: SubscriptionStatusCard
// Subscription status display
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/app_theme.dart';
import '../badges/premium_badge.dart';
import '../buttons/gradient_button.dart';

/// Subscription status card widget
/// Displays current subscription status and details
class SubscriptionStatusCard extends ConsumerWidget {
  final String planName;
  final String? status; // "active", "expired", "cancelled", etc.
  final DateTime? expiresAt;
  final bool isPremium;
  final VoidCallback? onManage;
  final VoidCallback? onUpgrade;

  const SubscriptionStatusCard({
    Key? key,
    required this.planName,
    this.status,
    this.expiresAt,
    this.isPremium = false,
    this.onManage,
    this.onUpgrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    Color getStatusColor() {
      switch (status?.toLowerCase()) {
        case 'active':
          return AppColors.onlineGreen;
        case 'expired':
        case 'cancelled':
          return AppColors.notificationRed;
        default:
          return secondaryTextColor;
      }
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        gradient: isPremium ? AppTheme.accentGradient : null,
        color: isPremium ? null : surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isPremium ? Colors.transparent : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPremium)
                PremiumBadge(isPremium: true, fontSize: 12),
              if (isPremium) SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Text(
                  planName,
                  style: AppTypography.h2.copyWith(
                    color: isPremium ? Colors.white : textColor,
                  ),
                ),
              ),
              if (status != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  ),
                  child: Text(
                    status!.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (expiresAt != null) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isPremium
                      ? Colors.white70
                      : secondaryTextColor,
                ),
                SizedBox(width: AppSpacing.spacingSM),
                Text(
                  status?.toLowerCase() == 'active'
                      ? 'Renews ${_formatDate(expiresAt!)}'
                      : 'Expires ${_formatDate(expiresAt!)}',
                  style: AppTypography.body.copyWith(
                    color: isPremium
                        ? Colors.white70
                        : secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
          if (onManage != null || onUpgrade != null) ...[
            SizedBox(height: AppSpacing.spacingLG),
            Row(
              children: [
                if (onManage != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onManage,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isPremium
                              ? Colors.white
                              : AppColors.accentPurple,
                        ),
                      ),
                      child: Text(
                        'Manage',
                        style: AppTypography.button.copyWith(
                          color: isPremium
                              ? Colors.white
                              : AppColors.accentPurple,
                        ),
                      ),
                    ),
                  ),
                if (onManage != null && onUpgrade != null)
                  SizedBox(width: AppSpacing.spacingMD),
                if (onUpgrade != null)
                  Expanded(
                    child: GradientButton(
                      text: 'Upgrade',
                      onPressed: onUpgrade,
                      isFullWidth: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays < 0) {
      return '${difference.inDays.abs()} days ago';
    } else if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'tomorrow';
    } else if (difference.inDays < 7) {
      return 'in ${difference.inDays} days';
    } else if (difference.inDays < 30) {
      return 'in ${(difference.inDays / 7).floor()} weeks';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
