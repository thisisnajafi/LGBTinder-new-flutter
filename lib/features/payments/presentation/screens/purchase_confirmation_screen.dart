import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import 'subscription_management_screen.dart';
import 'google_play_purchase_history_screen.dart';

/// Purchase Confirmation Screen - Success
/// Shown after successful purchase
class PurchaseConfirmationScreen extends StatelessWidget {
  final String productName;
  final double? price;
  final String? currency;
  final DateTime? purchaseDate;
  final bool isSubscription;
  final String? planName;
  final DateTime? expiryDate;

  const PurchaseConfirmationScreen({
    Key? key,
    required this.productName,
    this.price,
    this.currency,
    this.purchaseDate,
    this.isSubscription = false,
    this.planName,
    this.expiryDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.spacingXXL),

              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.onlineGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.onlineGreen,
                ),
              ),

              SizedBox(height: AppSpacing.spacingXL),

              // Success Message
              Text(
                'Purchase Successful!',
                style: AppTypography.h1.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.spacingMD),

              Text(
                'Your purchase has been completed successfully',
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.spacingXXL),

              // Purchase Details Card
              Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  border: Border.all(
                    color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Details',
                      style: AppTypography.h3.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                    _buildDetailRow('Product', productName, textColor, secondaryTextColor),
                    if (price != null)
                      _buildDetailRow(
                        'Price',
                        '${_formatPrice(price!, currency ?? 'USD')}',
                        textColor,
                        secondaryTextColor,
                      ),
                    if (purchaseDate != null)
                      _buildDetailRow(
                        'Purchase Date',
                        DateFormat('MMM d, y HH:mm').format(purchaseDate!),
                        textColor,
                        secondaryTextColor,
                      ),
                    if (isSubscription && planName != null)
                      _buildDetailRow('Plan', planName!, textColor, secondaryTextColor),
                    if (isSubscription && expiryDate != null)
                      _buildDetailRow(
                        'Expires',
                        DateFormat('MMM d, y').format(expiryDate!),
                        textColor,
                        secondaryTextColor,
                      ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.spacingXL),

              // Actions
              Column(
                children: [
                  if (isSubscription)
                    GradientButton(
                      text: 'Manage Subscription',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionManagementScreen(),
                          ),
                        );
                      },
                      isFullWidth: true,
                    ),
                  if (isSubscription) SizedBox(height: AppSpacing.spacingMD),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GooglePlayPurchaseHistoryScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentPurple,
                      side: BorderSide(color: AppColors.accentPurple),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('View Purchase History'),
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  TextButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: Text(
                      'Continue',
                      style: AppTypography.body.copyWith(
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price, String currency) {
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    return '$symbol${price.toStringAsFixed(2)}';
  }
}

/// Purchase Error Screen
/// Shown when purchase fails
class PurchaseErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final String? userMessage;
  final String? suggestedAction;
  final bool retryable;
  final VoidCallback? onRetry;
  final VoidCallback? onContactSupport;

  const PurchaseErrorScreen({
    Key? key,
    this.errorMessage,
    this.userMessage,
    this.suggestedAction,
    this.retryable = false,
    this.onRetry,
    this.onContactSupport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.spacingXXL),

              // Error Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.accentRed,
                ),
              ),

              SizedBox(height: AppSpacing.spacingXL),

              // Error Message
              Text(
                'Purchase Failed',
                style: AppTypography.h1.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSpacing.spacingMD),

              Text(
                userMessage ?? errorMessage ?? 'An error occurred while processing your purchase',
                style: AppTypography.body.copyWith(
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),

              if (suggestedAction != null) ...[
                SizedBox(height: AppSpacing.spacingLG),
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(
                      color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.accentYellow,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Text(
                          suggestedAction!,
                          style: AppTypography.body.copyWith(
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.spacingXXL),

              // Actions
              Column(
                children: [
                  if (retryable && onRetry != null)
                    GradientButton(
                      text: 'Retry Purchase',
                      onPressed: onRetry,
                      isFullWidth: true,
                    ),
                  if (retryable && onRetry != null) SizedBox(height: AppSpacing.spacingMD),
                  if (onContactSupport != null)
                    OutlinedButton(
                      onPressed: onContactSupport,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentPurple,
                        side: BorderSide(color: AppColors.accentPurple),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Contact Support'),
                    ),
                  SizedBox(height: AppSpacing.spacingMD),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Go Back',
                      style: AppTypography.body.copyWith(
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
