import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../data/models/payment_method.dart';

/// Payment method tile widget - displays a saved payment method
class PaymentMethodTile extends ConsumerWidget {
  final PaymentMethod paymentMethod;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PaymentMethodTile({
    Key? key,
    required this.paymentMethod,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isSelected
        ? AppColors.primaryLight.withOpacity(0.1)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final borderColor = isSelected
        ? AppColors.primaryLight
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return Card(
      color: backgroundColor,
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        side: BorderSide(
          color: borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              // Payment method icon
              _buildPaymentIcon(isDark),

              SizedBox(width: AppSpacing.spacingMD),

              // Payment method details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display name
                    Text(
                      paymentMethod.displayName,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Expiry date for cards
                    if (paymentMethod.type == 'card' && paymentMethod.expiryDateString.isNotEmpty)
                      Text(
                        'Expires ${paymentMethod.expiryDateString}',
                        style: AppTypography.bodySmall.copyWith(
                          color: paymentMethod.isCardExpired
                              ? AppColors.feedbackError
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),

                    // Status indicators
                    Row(
                      children: [
                        if (paymentMethod.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Default',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        if (paymentMethod.isExpired || paymentMethod.isCardExpired)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.feedbackError.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Expired',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.feedbackError,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.feedbackError,
                    size: 20,
                  ),
                ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(bool isDark) {
    IconData iconData;
    Color iconColor;

    switch (paymentMethod.type) {
      case 'card':
        switch (paymentMethod.brand.toLowerCase()) {
          case 'visa':
            iconData = Icons.credit_card;
            iconColor = const Color(0xFF1A1F71); // Visa blue
            break;
          case 'mastercard':
            iconData = Icons.credit_card;
            iconColor = const Color(0xFFEB001B); // Mastercard red
            break;
          case 'amex':
          case 'american_express':
            iconData = Icons.credit_card;
            iconColor = const Color(0xFF006FCF); // Amex blue
            break;
          default:
            iconData = Icons.credit_card;
            iconColor = AppColors.primaryLight;
        }
        break;
      case 'paypal':
        iconData = Icons.account_balance_wallet;
        iconColor = const Color(0xFF0070BA); // PayPal blue
        break;
      case 'apple_pay':
        iconData = Icons.apple;
        iconColor = isDark ? Colors.white : Colors.black;
        break;
      case 'google_pay':
        iconData = Icons.payment;
        iconColor = const Color(0xFF4285F4); // Google blue
        break;
      default:
        iconData = Icons.payment;
        iconColor = AppColors.primaryLight;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
}
