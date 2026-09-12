// Screen: BillingHistoryScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/app_logger.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../widgets/error_handling/empty_state.dart';
import '../features/payments/providers/payment_providers.dart';
import '../core/responsive/responsive.dart';

/// Billing history screen - View payment transactions
class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  ConsumerState<BillingHistoryScreen> createState() =>
      _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends ConsumerState<BillingHistoryScreen> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadBillingHistory();
  }

  Future<void> _loadBillingHistory({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final historyList = await ref.read(paymentServiceProvider).getPaymentHistory(
            page: refresh ? 1 : _page,
            limit: 20,
          );

      if (!mounted) return;
      setState(() {
        final mapped = historyList.map((item) {
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
        if (refresh) {
          _transactions = mapped;
          _page = 2;
        } else {
          _transactions = [..._transactions, ...mapped];
          _page += 1;
        }
        _hasMore = historyList.length >= 20;
      });
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load billing history',
        tag: 'BillingHistory',
        error: e,
        stackTrace: stack,
      );
      if (mounted && refresh) {
        setState(() {
          _transactions = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load billing history')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
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
      case 'success':
        return AppColors.feedbackSuccess;
      case 'pending':
        return AppColors.feedbackWarning;
      case 'failed':
      case 'cancelled':
        return AppColors.feedbackError;
      case 'refunded':
        return AppColors.feedbackInfo;
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
              : PremiumRefreshIndicator(
                  onRefresh: _loadBillingHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingLG,
                      vertical: AppSpacing.spacingSM,
                    ),
                    itemCount: _transactions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _transactions.length) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.spacingLG,
                          ),
                          child: Center(
                            child: _isLoadingMore
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: () =>
                                        _loadBillingHistory(refresh: false),
                                    child: const Text('Load more'),
                                  ),
                          ),
                        );
                      }
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
                                    child: AppText(
                                      (transaction['description'] as String?)
                                                  ?.isNotEmpty ==
                                              true
                                          ? transaction['description'] as String
                                          : 'Payment',
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ),
                                  Flexible(
                                    child: AppText(
                                      _formatCurrency(
                                        transaction['amount'] as double,
                                        transaction['currency'] as String,
                                      ),
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.end,
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
