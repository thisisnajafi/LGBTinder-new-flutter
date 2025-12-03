// Screen: SubscriptionManagementScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/badges/premium_badge.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/confirmation_dialog.dart';
import '../widgets/modals/alert_dialog_custom.dart';
import 'premium/premium_subscription_screen.dart';

/// Subscription management screen - Manage premium subscription
class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends ConsumerState<SubscriptionManagementScreen> {
  bool _isPremium = false; // TODO: Get from provider
  String _currentPlan = 'Monthly';
  DateTime? _renewalDate;
  bool _autoRenew = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    // TODO: Load subscription from API
    setState(() {
      _isPremium = true;
      _currentPlan = 'Monthly';
      _renewalDate = DateTime.now().add(const Duration(days: 30));
      _autoRenew = true;
    });
  }

  Future<void> _handleCancelSubscription() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Cancel Subscription',
      message: 'Are you sure you want to cancel your premium subscription? You will lose access to premium features at the end of your billing period.',
      confirmText: 'Cancel Subscription',
      cancelText: 'Keep Subscription',
      isDestructive: true,
    );

    if (confirmed == true) {
      // TODO: Cancel subscription via API
      setState(() {
        _autoRenew = false;
      });
      AlertDialogCustom.show(
        context,
        title: 'Subscription Cancelled',
        message: 'Your subscription will remain active until ${_formatDate(_renewalDate)}. You can reactivate anytime.',
        icon: Icons.info,
        iconColor: AppColors.warningYellow,
      );
    }
  }

  Future<void> _handleReactivate() async {
    // TODO: Reactivate subscription via API
    setState(() {
      _autoRenew = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription reactivated')),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
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
        title: 'Subscription',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Current subscription status
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              color: _isPremium
                  ? AppColors.accentPurple.withOpacity(0.2)
                  : surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: _isPremium ? AppColors.accentPurple : borderColor,
              ),
            ),
            child: Column(
              children: [
                if (_isPremium) PremiumBadge(isPremium: true, fontSize: 16),
                if (_isPremium) SizedBox(height: AppSpacing.spacingMD),
                Text(
                  _isPremium ? 'Premium Active' : 'No Active Subscription',
                  style: AppTypography.h2.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isPremium) ...[
                  SizedBox(height: AppSpacing.spacingSM),
                  Text(
                    'Current Plan: $_currentPlan',
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  if (_renewalDate != null) ...[
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      _autoRenew
                          ? 'Renews on ${_formatDate(_renewalDate)}'
                          : 'Expires on ${_formatDate(_renewalDate)}',
                      style: AppTypography.caption.copyWith(
                        color: _autoRenew
                            ? AppColors.onlineGreen
                            : AppColors.warningYellow,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),

          if (!_isPremium) ...[
            // Upgrade to premium
            SectionHeader(
              title: 'Upgrade to Premium',
              icon: Icons.star,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            GradientButton(
              text: 'View Premium Plans',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumSubscriptionScreen(),
                  ),
                );
              },
              isFullWidth: true,
              icon: Icons.arrow_forward,
            ),
            SizedBox(height: AppSpacing.spacingXXL),
          ] else ...[
            // Subscription details
            SectionHeader(
              title: 'Subscription Details',
              icon: Icons.info,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _buildDetailRow(
              label: 'Plan',
              value: _currentPlan,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _buildDetailRow(
              label: 'Status',
              value: _autoRenew ? 'Active' : 'Cancelled',
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            if (_renewalDate != null) ...[
              SizedBox(height: AppSpacing.spacingSM),
              _buildDetailRow(
                label: _autoRenew ? 'Next Billing Date' : 'Expiration Date',
                value: _formatDate(_renewalDate),
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              ),
            ],
            DividerCustom(),
            SizedBox(height: AppSpacing.spacingLG),

            // Actions
            SectionHeader(
              title: 'Actions',
              icon: Icons.settings,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            if (!_autoRenew)
              GradientButton(
                text: 'Reactivate Subscription',
                onPressed: _handleReactivate,
                isFullWidth: true,
                icon: Icons.refresh,
              )
            else
              OutlinedButton(
                onPressed: _handleCancelSubscription,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                  side: BorderSide(color: AppColors.notificationRed),
                ),
                child: Text(
                  'Cancel Subscription',
                  style: AppTypography.button.copyWith(
                    color: AppColors.notificationRed,
                  ),
                ),
              ),
            SizedBox(height: AppSpacing.spacingMD),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumSubscriptionScreen(),
                  ),
                );
              },
              child: Text(
                'Change Plan',
                style: AppTypography.button.copyWith(
                  color: AppColors.accentPurple,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.spacingXXL),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
