// Screen: PaymentMethodsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../core/constants/api_endpoints.dart';
import '../core/providers/api_providers.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/modals/confirmation_dialog.dart';
import '../widgets/error_handling/empty_state.dart';
import 'add_payment_method_screen.dart';

/// Payment methods screen — manage saved cards and wallets.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get<Map<String, dynamic>>(
        ApiEndpoints.userPaymentMethods,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as List<dynamic>? ?? [];
        setState(() {
          _paymentMethods =
              data.map((method) => method as Map<String, dynamic>).toList();
        });
      } else {
        setState(() => _paymentMethods = []);
      }
    } catch (_) {
      setState(() => _paymentMethods = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddMethod() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
    );
    if (mounted) _loadPaymentMethods();
  }

  Future<void> _handleSetDefault(String id) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.patch<Map<String, dynamic>>(
        ApiEndpoints.userPaymentMethods,
        data: {'payment_method_id': id},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      setState(() {
        for (final method in _paymentMethods) {
          method['isDefault'] = method['id'] == id;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default payment method updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update default payment method: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Payment Method',
      message: 'Are you sure you want to remove this payment method?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.delete<Map<String, dynamic>>(
        '${ApiEndpoints.userPaymentMethods}/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      setState(() {
        _paymentMethods.removeWhere((method) => method['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove payment method: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return PremiumDetailScaffold(
      title: 'Payment Methods',
      subtitle: 'Cards and wallets on file',
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingLG),
          child: GradientButton(
            text: 'Add Payment Method',
            iconPath: AppIcons.add,
            onPressed: _openAddMethod,
            isFullWidth: true,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentMethods.isEmpty
              ? EmptyState(
                  title: 'No Payment Methods',
                  message: 'Add a payment method to get started',
                  iconPath: AppIcons.card,
                  actionLabel: 'Add Payment Method',
                  onAction: _openAddMethod,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingLG,
                    vertical: AppSpacing.spacingSM,
                  ),
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    final isDefault = method['isDefault'] == true;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.spacingMD,
                      ),
                      child: PremiumShell(
                        margin: EdgeInsets.zero,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.accentViolet
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${method['brand']} •••• ${method['last4']}',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isDefault) ...[
                                        const SizedBox(
                                          width: AppSpacing.spacingSM,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.spacingSM,
                                            vertical: AppSpacing.spacingXS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentViolet
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.radiusSM,
                                            ),
                                          ),
                                          child: Text(
                                            'DEFAULT',
                                            style: AppTypography.caption
                                                .copyWith(
                                              color: AppColors.accentViolet,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.spacingXS),
                                  Text(
                                    'Expires ${method['expiry']}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: AppSvgIcon(
                                assetPath: AppIcons.more,
                                size: 20,
                                color: muted,
                              ),
                              onSelected: (value) {
                                if (value == 'default') {
                                  _handleSetDefault(method['id'] as String);
                                } else if (value == 'delete') {
                                  _handleDelete(method['id'] as String);
                                }
                              },
                              itemBuilder: (context) => [
                                if (!isDefault)
                                  const PopupMenuItem(
                                    value: 'default',
                                    child: Text('Set as Default'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppColors.feedbackError,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
