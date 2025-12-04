// Screen: BillingHistoryScreen
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
import '../widgets/loading/skeleton_loader.dart';
import '../core/constants/api_endpoints.dart';
import '../features/payments/providers/payment_providers.dart';
import '../shared/models/api_response.dart';

/// Billing history screen - View payment transactions
class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends ConsumerState<BillingHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadBillingHistory();
  }

  Future<void> _loadBillingHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final historyList = await ref.read(paymentServiceProvider).getPaymentHistory();

      setState(() {
        _transactions = historyList.map((item) {
          return {
            'id': item.id,
            'date': item.createdAt,
            'description': item.description,
            'amount': item.amount,
            'currency': item.currency,
            'status': item.status,
            'method': item.type, // Use type as method (subscription, superlike_pack, etc.)
          };
        }).toList();
      });
    } catch (e) {
      // Handle error - keep empty list
      setState(() {
        _transactions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount, String currency) {
    return '${currency.toUpperCase()} ${amount.toStringAsFixed(2)}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'succeeded':
        return AppColors.onlineGreen;
      case 'pending':
        return AppColors.warningYellow;
      case 'failed':
      case 'cancelled':
        return AppColors.notificationRed;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBarCustom(
        title: 'Billing History',
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? EmptyState(
                  title: 'No Transactions',
                  message: 'Your payment history will appear here.',
                  icon: Icons.receipt_long,
                )
              : RefreshIndicator(
                  onRefresh: _loadBillingHistory,
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
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
                                  child: Text(
                                    transaction['description'],
                                    style: AppTypography.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatCurrency(transaction['amount'], transaction['currency']),
                                  style: AppTypography.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.spacingXS),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(transaction['date']),
                                  style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                                ),
                                Text(
                                  transaction['method'],
                                  style: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.spacingXS),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM, vertical: AppSpacing.spacingXS),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(transaction['status']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                ),
                                child: Text(
                                  transaction['status'],
                                  style: AppTypography.bodySmall.copyWith(color: _getStatusColor(transaction['status'])),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
