// Screen: PaymentScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/widgets/app_page_scaffold.dart';
import '../core/widgets/app_page_header.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/bottom_sheet_custom.dart';
import '../routes/app_router.dart';
import '../features/payments/providers/payment_providers.dart';

/// Payment screen - Billing history and subscriptions (Stripe cards removed)
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final history = await paymentService.getUserPaymentHistory(page: 1, limit: 20);
      final methods = await paymentService.getPaymentMethodsCatalog();

      final historyRaw = history['payments'] ??
          history['data']?['payments'] ??
          history['data'] ??
          const [];
      final methodsRaw = methods['payment_methods'] ??
          methods['methods'] ??
          methods['data'] ??
          const [];

      setState(() {
        _transactions = historyRaw is List
            ? historyRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _paymentMethods = methodsRaw is List
            ? methodsRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      });
    } catch (_) {
      setState(() {
        _transactions = [];
        _paymentMethods = [];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    return AppPageScaffold(
      title: 'Payment',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Recent transactions
          SectionHeader(
            title: 'Recent Transactions',
            icon: Icons.history,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_transactions.isEmpty)
            Text(
              'No transactions found.',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            )
          else
            ..._transactions.take(5).map((t) {
              final amount = (t['amount'] as num?)?.toDouble() ?? 0;
              final created = t['created_at']?.toString() ??
                  t['date']?.toString() ??
                  '—';
              final status = t['status']?.toString() ?? 'unknown';
              final title = t['description']?.toString() ??
                  t['type']?.toString() ??
                  'Payment';
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                child: _buildTransactionItem(
                  title: title,
                  amount: amount,
                  date: created,
                  status: status,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
              );
            }),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          SectionHeader(
            title: 'Payment Methods',
            icon: Icons.account_balance_wallet_outlined,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          if (_isLoading)
            const SizedBox.shrink()
          else if (_paymentMethods.isEmpty)
            Text(
              'No payment methods available.',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            )
          else
            ..._paymentMethods.take(3).map((m) {
              final name = m['name']?.toString() ?? m['title']?.toString() ?? 'Method';
              final type = m['type']?.toString() ?? '';
              final active = m['is_active'] == true || m['enabled'] == true;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.credit_card, color: AppColors.accentPurple),
                title: Text(name, style: AppTypography.body.copyWith(color: textColor)),
                subtitle: type.isNotEmpty
                    ? Text(type, style: AppTypography.caption.copyWith(color: secondaryTextColor))
                    : null,
                trailing: Icon(
                  active ? Icons.check_circle : Icons.remove_circle_outline,
                  color: active ? AppColors.onlineGreen : secondaryTextColor,
                ),
              );
            }),
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
          ListTile(
            leading: Icon(Icons.manage_accounts, color: AppColors.accentPurple),
            title: Text(
              'Subscription Management',
              style: AppTypography.body.copyWith(color: textColor),
            ),
            subtitle: Text(
              'Manage active subscriptions',
              style: AppTypography.caption.copyWith(color: secondaryTextColor),
            ),
            trailing: Icon(Icons.chevron_right, color: secondaryTextColor),
            onTap: () => context.push(AppRoutes.subscriptionManagement),
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
