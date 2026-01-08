import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../data/models/google_play_purchase_history.dart';

/// Widget to display a single purchase history item
class PurchaseHistoryItem extends StatelessWidget {
  final GooglePlayPurchaseHistory purchase;
  final VoidCallback? onTap;

  const PurchaseHistoryItem({
    Key? key,
    required this.purchase,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Type Icon
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacingSM),
                    decoration: BoxDecoration(
                      color: purchase.isSubscription
                          ? AppColors.accentPurple.withOpacity(0.2)
                          : AppColors.accentBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    ),
                    child: Icon(
                      purchase.isSubscription ? Icons.sync : Icons.star,
                      color: purchase.isSubscription
                          ? AppColors.accentPurple
                          : AppColors.accentBlue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  // Product Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.productName,
                          style: AppTypography.h3.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          purchase.productId,
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  _buildStatusBadge(),
                ],
              ),

              SizedBox(height: AppSpacing.spacingMD),

              // Details Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        purchase.formattedPrice,
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Purchase Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Purchase Date',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        purchase.purchaseDate != null
                            ? DateFormat('MMM d, y').format(purchase.purchaseDate!)
                            : 'N/A',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Expiry Date (for subscriptions)
              if (purchase.isSubscription && purchase.expiryDate != null) ...[
                SizedBox(height: AppSpacing.spacingMD),
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingSM),
                  decoration: BoxDecoration(
                    color: purchase.isActive
                        ? AppColors.onlineGreen.withOpacity(0.1)
                        : AppColors.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        purchase.isActive ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: purchase.isActive
                            ? AppColors.onlineGreen
                            : AppColors.accentRed,
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                      Expanded(
                        child: Text(
                          purchase.isActive
                              ? 'Expires: ${DateFormat('MMM d, y').format(purchase.expiryDate!)}'
                              : 'Expired: ${DateFormat('MMM d, y').format(purchase.expiryDate!)}',
                          style: AppTypography.caption.copyWith(
                            color: purchase.isActive
                                ? AppColors.onlineGreen
                                : AppColors.accentRed,
                          ),
                        ),
                      ),
                      if (purchase.autoRenewing)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingSM,
                            vertical: AppSpacing.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onlineGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                          ),
                          child: Text(
                            'Auto-renew',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.onlineGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    Color textColor;
    String statusText;

    switch (purchase.status.toLowerCase()) {
      case 'completed':
        badgeColor = AppColors.onlineGreen;
        textColor = Colors.white;
        statusText = 'Completed';
        break;
      case 'pending':
        badgeColor = Colors.orange;
        textColor = Colors.white;
        statusText = 'Pending';
        break;
      case 'cancelled':
        badgeColor = Colors.grey;
        textColor = Colors.white;
        statusText = 'Cancelled';
        break;
      case 'refunded':
        badgeColor = AppColors.accentRed;
        textColor = Colors.white;
        statusText = 'Refunded';
        break;
      default:
        badgeColor = Colors.grey;
        textColor = Colors.white;
        statusText = purchase.status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
      ),
      child: Text(
        statusText,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
