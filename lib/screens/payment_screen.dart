// Screen: PaymentScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/payments/providers/payment_providers.dart';
import '../routes/app_router.dart';

/// Payment screen — billing overview, methods, and shortcuts.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

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
      final history =
          await paymentService.getUserPaymentHistory(page: 1, limit: 20);
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

  Color _statusColor(String status) {
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
      title: 'Payment',
      subtitle: 'Transactions and billing',
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.spacingXXL),
        children: [
          PremiumSettingsGroup(
            title: 'Recent transactions',
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingLG),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_transactions.isEmpty)
                Text(
                  'No transactions found.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
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
                  final statusColor = _statusColor(status);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accentViolet.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusMD),
                          ),
                          child: Center(
                            child: AppSvgIcon(
                              assetPath: AppIcons.card,
                              size: 20,
                              color: AppColors.accentViolet,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                created,
                                style: theme.textTheme.bodySmall?.copyWith(
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.spacingSM,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.radiusSM),
                              ),
                              child: Text(
                                status,
                                style: AppTypography.bodySmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Payment methods',
            children: [
              if (_isLoading)
                const SizedBox.shrink()
              else if (_paymentMethods.isEmpty)
                Text(
                  'No payment methods available.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                  ),
                )
              else
                ..._paymentMethods.take(3).map((m) {
                  final name = m['name']?.toString() ??
                      m['title']?.toString() ??
                      'Method';
                  final type = m['type']?.toString() ?? '';
                  final active =
                      m['is_active'] == true || m['enabled'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accentViolet.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: AppSvgIcon(
                              assetPath: AppIcons.wallet,
                              size: 20,
                              color: AppColors.accentViolet,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (type.isNotEmpty)
                                Text(
                                  type,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AppSvgIcon(
                          assetPath: active
                              ? AppIcons.tickCircle
                              : AppIcons.getIconPath('minus-cirlce'),
                          size: 20,
                          color: active
                              ? AppColors.feedbackSuccess
                              : secondaryTextColor,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Manage',
            children: [
              PremiumSettingsTile(
                iconPath: AppIcons.receipt,
                title: 'Billing History',
                subtitle: 'View all transactions',
                onTap: () => context.push(AppRoutes.billingHistory),
              ),
              PremiumSettingsTile(
                iconPath: AppIcons.crown,
                title: 'Subscription Management',
                subtitle: 'Manage active subscriptions',
                accent: AppColors.accentRose,
                onTap: () => context.push(AppRoutes.subscriptionManagement),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
