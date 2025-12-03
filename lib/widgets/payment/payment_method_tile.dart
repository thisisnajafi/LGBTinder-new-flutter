// Widget: PaymentMethodTile
// Payment method list tile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';

/// Payment method tile widget
/// Displays payment method with icon, details, and actions
class PaymentMethodTile extends ConsumerWidget {
  final String type; // "card", "paypal", "apple_pay", etc.
  final String? last4; // Last 4 digits for cards
  final String? brand; // Card brand (Visa, Mastercard, etc.)
  final bool isDefault;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const PaymentMethodTile({
    Key? key,
    required this.type,
    this.last4,
    this.brand,
    this.isDefault = false,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  IconData _getIcon() {
    switch (type.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.payment;
      case 'apple_pay':
        return Icons.apple;
      case 'google_pay':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _getDisplayName() {
    switch (type.toLowerCase()) {
      case 'card':
        return brand != null
            ? '$brand •••• $last4'
            : 'Card •••• $last4';
      case 'paypal':
        return 'PayPal';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingSM,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault ? AppColors.accentPurple : borderColor,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          _getIcon(),
          color: AppColors.accentPurple,
          size: 32,
        ),
        title: Text(
          _getDisplayName(),
          style: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: isDefault
            ? Text(
                'Default payment method',
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentPurple,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.notificationRed,
                ),
                onPressed: onDelete,
              ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: secondaryTextColor,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
