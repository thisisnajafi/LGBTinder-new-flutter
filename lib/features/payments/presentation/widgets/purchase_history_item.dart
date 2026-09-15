import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../data/models/google_play_purchase_history.dart';
import '../../utils/purchase_status_style.dart';
import '../../../../core/responsive/responsive.dart';

/// Widget to display a single purchase history item
class PurchaseHistoryItem extends StatelessWidget {
  final GooglePlayPurchaseHistory purchase;
  final VoidCallback? onTap;

  const PurchaseHistoryItem({
    super.key,
    required this.purchase,
    this.onTap,
  });

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
                          ? AppColors.accentPurple.withValues(alpha: 0.2)
                          : AppColors.accentViolet.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    ),
                    child: AppSvgIcon(
                      assetPath: purchase.isSubscription
                          ? AppIcons.refreshCircle
                          : AppIcons.star,
                      color: purchase.isSubscription
                          ? AppColors.accentPurple
                          : AppColors.accentViolet,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  // Product Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          purchase.productName,
                          style: AppTypography.h3.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        AppText(
                          purchase.productId,
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackDetails = constraints.maxWidth < 320;
                  final priceColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      AppText(
                        purchase.formattedPrice,
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  );
                  final dateColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchased',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingXS),
                      AppText(
                        purchase.purchaseDate != null
                            ? DateFormat('MMM d, y').format(purchase.purchaseDate!)
                            : 'N/A',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  );

                  if (stackDetails) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        priceColumn,
                        SizedBox(height: AppSpacing.spacingSM),
                        dateColumn,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: priceColumn),
                      SizedBox(width: AppSpacing.spacingMD),
                      Expanded(child: dateColumn),
                    ],
                  );
                },
              ),

              // Expiry Date (for subscriptions)
              if (purchase.isSubscription && purchase.expiryDate != null) ...[
                SizedBox(height: AppSpacing.spacingMD),
                Container(
                  padding: EdgeInsets.all(AppSpacing.spacingSM),
                  decoration: BoxDecoration(
                    color: purchase.isActive
                        ? AppColors.onlineGreen.withValues(alpha: 0.1)
                        : AppColors.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                  ),
                  child: Row(
                    children: [
                      AppSvgIcon(
                        assetPath: purchase.isActive
                            ? AppIcons.checkCircle
                            : AppIcons.close,
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
                            color: AppColors.onlineGreen.withValues(alpha: 0.2),
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
    final style = PurchaseStatusStyle.fromStatus(purchase.status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        color: style.badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
      ),
      child: Text(
        style.label,
        style: AppTypography.caption.copyWith(
          color: style.foregroundColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
