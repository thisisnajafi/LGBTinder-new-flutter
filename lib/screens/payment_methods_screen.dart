// Screen: PaymentMethodsScreen
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
import '../widgets/modals/confirmation_dialog.dart';
import '../widgets/error_handling/empty_state.dart';
import 'add_payment_method_screen.dart';

/// Payment methods screen - Manage payment methods
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
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
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load payment methods from API
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _paymentMethods = [
          {
            'id': 'card_1',
            'type': 'card',
            'last4': '4242',
            'brand': 'Visa',
            'expiry': '12/25',
            'isDefault': true,
          },
          {
            'id': 'card_2',
            'type': 'card',
            'last4': '8888',
            'brand': 'Mastercard',
            'expiry': '06/26',
            'isDefault': false,
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSetDefault(String id) async {
    // TODO: Set default payment method via API
    setState(() {
      for (var method in _paymentMethods) {
        method['isDefault'] = method['id'] == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default payment method updated')),
    );
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

    if (confirmed == true) {
      // TODO: Delete payment method via API
      setState(() {
        _paymentMethods.removeWhere((method) => method['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method removed')),
      );
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Payment Methods',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _paymentMethods.isEmpty
                      ? EmptyState(
                          title: 'No Payment Methods',
                          message: 'Add a payment method to get started',
                          icon: Icons.credit_card,
                          actionLabel: 'Add Payment Method',
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPaymentMethodScreen(),
                              ),
                            ).then((_) => _loadPaymentMethods());
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(AppSpacing.spacingLG),
                          itemCount: _paymentMethods.length,
                          itemBuilder: (context, index) {
                            final method = _paymentMethods[index];
                            final isDefault = method['isDefault'] == true;
                            return Container(
                              margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                              padding: EdgeInsets.all(AppSpacing.spacingLG),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                                border: Border.all(
                                  color: isDefault
                                      ? AppColors.accentPurple
                                      : borderColor,
                                  width: isDefault ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.surfaceElevatedDark
                                              : AppColors.surfaceElevatedLight,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Icon(
                                          Icons.credit_card,
                                          color: AppColors.accentPurple,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.spacingMD),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${method['brand']} •••• ${method['last4']}',
                                                  style: AppTypography.h3.copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (isDefault) ...[
                                                  SizedBox(width: AppSpacing.spacingSM),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.spacingSM,
                                                      vertical: AppSpacing.spacingXS,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accentPurple.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                                    ),
                                                    child: Text(
                                                      'DEFAULT',
                                                      style: AppTypography.caption.copyWith(
                                                        color: AppColors.accentPurple,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SizedBox(height: AppSpacing.spacingXS),
                                            Text(
                                              'Expires ${method['expiry']}',
                                              style: AppTypography.caption.copyWith(
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: secondaryTextColor,
                                        ),
                                        itemBuilder: (context) => [
                                          if (!isDefault)
                                            PopupMenuItem(
                                              child: Text(
                                                'Set as Default',
                                                style: AppTypography.body.copyWith(color: textColor),
                                              ),
                                              onTap: () => _handleSetDefault(method['id']),
                                            ),
                                          PopupMenuItem(
                                            child: Text(
                                              'Delete',
                                              style: AppTypography.body.copyWith(
                                                color: AppColors.notificationRed,
                                              ),
                                            ),
                                            onTap: () => _handleDelete(method['id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Add button
                Padding(
                  padding: EdgeInsets.all(AppSpacing.spacingLG),
                  child: GradientButton(
                    text: 'Add Payment Method',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPaymentMethodScreen(),
                        ),
                      ).then((_) => _loadPaymentMethods());
                    },
                    isFullWidth: true,
                    icon: Icons.add,
                  ),
                ),
              ],
            ),
    );
  }
}
