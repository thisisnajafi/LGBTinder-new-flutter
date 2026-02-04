// Screen: PaymentScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/bottom_sheet_custom.dart';
import '../routes/app_router.dart';

/// Payment screen - Billing history and subscriptions (Stripe cards removed)
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = false;

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
        title: 'Payment',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Recent transactions
          SectionHeader(
            title: 'Recent Transactions',
            icon: Icons.history,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          _buildTransactionItem(
            title: 'Premium Subscription',
            amount: 9.99,
            date: 'Dec 15, 2024',
            status: 'Completed',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          _buildTransactionItem(
            title: 'Super Like Pack',
            amount: 4.99,
            date: 'Dec 10, 2024',
            status: 'Completed',
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Manage section
          SectionHeader(
            title: 'Manage',
            icon: Icons.settings,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ListTile(
            leading: Icon(Icons.receipt, color: AppColors.accentPurple),
            title: Text(
              'Billing History',
              style: AppTypography.body.copyWith(color: textColor),
            ),
            subtitle: Text(
              'View all transactions',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: secondaryTextColor,
            ),
            onTap: () {
              // Navigate to billing history
              context.push(AppRoutes.billingHistory);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required double amount,
    required String date,
    required String status,
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
            ),
            child: Icon(
              Icons.payment,
              color: AppColors.accentPurple,
              size: 20,
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  date,
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: AppTypography.h3.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.spacingXS),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingSM,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onlineGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onlineGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
