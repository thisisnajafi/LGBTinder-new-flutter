import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../data/models/sub_plan_bundle_pricing.dart';
import '../../data/models/subscription_plan.dart';

/// Widget for selecting subscription offers (Monthly, Quarterly, Annual)
class OfferSelectionWidget extends StatelessWidget {
  final List<SubPlan> offers;
  final SubPlan? selectedOffer;
  final Function(SubPlan) onOfferSelected;
  final SubPlan? recommendedOffer;

  const OfferSelectionWidget({
    Key? key,
    required this.offers,
    this.selectedOffer,
    required this.onOfferSelected,
    this.recommendedOffer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedOffers = List<SubPlan>.from(offers)
      ..sort((a, b) => (a.durationDays ?? 0).compareTo(b.durationDays ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Billing Cycle',
          style: AppTypography.h3.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.spacingMD),
        Wrap(
          spacing: AppSpacing.spacingMD,
          runSpacing: AppSpacing.spacingMD,
          children: sortedOffers.map((offer) {
            final isSelected = selectedOffer?.id == offer.id;
            final isRecommended = recommendedOffer?.id == offer.id;
            final pricing = SubPlanBundlePricing.forOption(offer, sortedOffers);

            return GestureDetector(
              onTap: () => onOfferSelected(offer),
              child: Container(
                width: _getOfferWidth(sortedOffers.length),
                padding: EdgeInsets.all(AppSpacing.spacingMD),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentPurple.withOpacity(0.2)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentPurple
                        : (isRecommended
                            ? AppColors.accentYellow.withOpacity(0.5)
                            : borderColor),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recommended badge
                    if (isRecommended)
                      Container(
                        margin: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingSM,
                          vertical: AppSpacing.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow,
                          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: AppSpacing.spacingXS),
                            Text(
                              'Recommended',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Duration
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.durationLabel,
                            style: AppTypography.h3.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (pricing.hasBundleDiscount &&
                            pricing.discountPercent != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacingSM,
                              vertical: AppSpacing.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.feedbackSuccess,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.radiusSM),
                            ),
                            child: Text(
                              '${pricing.discountPercent}% OFF',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: AppSpacing.spacingSM),

                    // Price
                    Text(
                      _formatPrice(pricing.sellingPrice, offer.currency),
                      style: AppTypography.h2.copyWith(
                        color: isSelected
                            ? AppColors.accentPurple
                            : textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (pricing.hasBundleDiscount &&
                        pricing.originalPrice != null) ...[
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        'Was ${_formatPrice(pricing.originalPrice!, offer.currency)}',
                        style: AppTypography.body.copyWith(
                          color: secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],

                    // Per month price (for non-monthly offers)
                    if (offer.monthsCount > 1) ...[
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        '${_formatPrice(offer.perMonthPrice, offer.currency)}/month',
                        style: AppTypography.caption.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ],

                    // Selection indicator
                    if (isSelected) ...[
                      SizedBox(height: AppSpacing.spacingSM),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.accentPurple,
                            size: 16,
                          ),
                          SizedBox(width: AppSpacing.spacingXS),
                          Text(
                            'Selected',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  double _getOfferWidth(int offerCount) {
    if (offerCount == 1) return double.infinity;
    if (offerCount == 2) return 150;
    return 120; // For 3+ offers
  }

  String _formatPrice(double price, String currency) {
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    return '$symbol${price.toStringAsFixed(2)}';
  }
}
