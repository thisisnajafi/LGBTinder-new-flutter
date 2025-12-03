import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../models/payment_method.dart';

/// Payment method selector widget
/// Allows users to choose payment method (credit card, PayPal, etc.)
class PaymentMethodSelector extends ConsumerStatefulWidget {
  final List<PaymentMethod> paymentMethods;
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod)? onMethodSelected;
  final bool showAddNew;

  const PaymentMethodSelector({
    Key? key,
    required this.paymentMethods,
    this.selectedMethod,
    this.onMethodSelected,
    this.showAddNew = true,
  }) : super(key: key);

  @override
  ConsumerState<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends ConsumerState<PaymentMethodSelector> {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Existing payment methods
        ...widget.paymentMethods.map((method) => _buildPaymentMethodTile(
          context,
          method,
          isSelected: method.id == widget.selectedMethod?.id,
        )),

        // Add new payment method
        if (widget.showAddNew) ...[
          const SizedBox(height: 8),
          _buildAddNewMethodTile(context),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodTile(BuildContext context, PaymentMethod method, {bool isSelected = false}) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: () => widget.onMethodSelected?.call(method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Payment method icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMethodColor(method.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: _getMethodIcon(method.type),
                    size: 24,
                    color: _getMethodColor(method.type),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Method details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected) ...[
                const SizedBox(width: 12),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewMethodTile(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to add payment method screen
          context.go('/add-payment-method');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.plus,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Payment Method',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add a new credit card or payment method',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              AppSvgIcon(
                assetPath: AppIcons.arrowRight,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return AppIcons.creditCard;
      case PaymentMethodType.paypal:
        return AppIcons.paypal;
      case PaymentMethodType.applePay:
        return AppIcons.apple;
      case PaymentMethodType.googlePay:
        return AppIcons.google;
      default:
        return AppIcons.payment;
    }
  }

  Color _getMethodColor(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return AppColors.primaryLight;
      case PaymentMethodType.paypal:
        return const Color(0xFF0070BA); // PayPal blue
      case PaymentMethodType.applePay:
        return Colors.black;
      case PaymentMethodType.googlePay:
        return Colors.blue;
      default:
        return AppColors.textSecondary;
    }
  }
}
