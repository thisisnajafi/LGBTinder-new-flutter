// Screen: BillingHistoryScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/error_handling/empty_state.dart';
import '../features/payments/providers/payment_providers.dart';

/// Billing history screen - View payment transactions
class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  ConsumerState<BillingHistoryScreen> createState() =>
      _BillingHistoryScreenState();
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
      final historyList =
          await ref.read(paymentServiceProvider).getPaymentHistory();

      setState(() {
        _transactions = historyList.map((item) {
          return {
            'id': item.id,
            'date': item.createdAt,
            'description': item.description,
            'amount': item.amount,
            'currency': item.currency,
            'status': item.status,
            'method': item.type,
          };
        }).toList();
      });
    } catch (e) {
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
        return AppColors.feedbackSuccess;
      case 'pending':
        return AppColors.feedbackWarning;
      case 'failed':
      case 'cancelled':
        return AppColors.feedbackError;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return PremiumDetailScaffold(
      title: 'Billing History',
      subtitle: 'Your payment transactions',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const EmptyState(
                  title: 'No Transactions',
                  message: 'Your payment history will appear here.',
                  iconPath: AppIcons.receipt,
                )
              : RefreshIndicator(
                  onRefresh: _loadBillingHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingLG,
                      vertical: AppSpacing.spacingSM,
                    ),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      final statusColor =
                          _getStatusColor(transaction['status'] as String);

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.spacingMD,
                        ),
                        child: PremiumShell(
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentViolet
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.radiusMD,
                                      ),
                                    ),
                                    child: Center(
                                      child: AppSvgIcon(
                                        assetPath: AppIcons.receipt,
                                        size: 20,
                                        color: AppColors.accentViolet,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: AppSpacing.spacingMD,
                                  ),
                                  Expanded(
                                    child: Text(
                                      transaction['description'] as String,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(
                                      transaction['amount'] as double,
                                      transaction['currency'] as String,
                                    ),
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.spacingSM),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(
                                      transaction['date'] as DateTime,
                                    ),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    transaction['method'] as String,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.spacingSM),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacingSM,
                                    vertical: AppSpacing.spacingXS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.radiusSM,
                                    ),
                                  ),
                                  child: Text(
                                    transaction['status'] as String,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
