import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
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
          children: offers.map((offer) {
            final isSelected = selectedOffer?.id == offer.id;
            final isRecommended = recommendedOffer?.id == offer.id;
            final hasDiscount = _hasDiscount(offer);
            final savings = _calculateSavings(offer, offers);

            return GestureDetector(
              onTap: () => onOfferSelected(offer),
              child: Container(
                width: _getOfferWidth(offers.length),
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
                    Text(
                      _getDurationLabel(offer.duration),
                      style: AppTypography.h3.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: AppSpacing.spacingSM),

                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrice(offer.price, offer.currency),
                          style: AppTypography.h2.copyWith(
                            color: isSelected
                                ? AppColors.accentPurple
                                : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasDiscount) ...[
                          SizedBox(width: AppSpacing.spacingSM),
                          Text(
                            _formatPrice(_getOriginalPrice(offer, offers), offer.currency),
                            style: AppTypography.body.copyWith(
                              color: secondaryTextColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Savings
                    if (savings > 0) ...[
                      SizedBox(height: AppSpacing.spacingXS),
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
                          'Save ${_formatPrice(savings, offer.currency)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onlineGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    // Per month price (for non-monthly offers)
                    if (offer.duration != 'monthly' && offer.duration != 'month') ...[
                      SizedBox(height: AppSpacing.spacingXS),
                      Text(
                        '${_formatPrice(_getPerMonthPrice(offer), offer.currency)}/month',
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

  String _getDurationLabel(String? duration) {
    if (duration == null) return 'Monthly';
    final d = duration.toLowerCase();
    if (d.contains('month') && !d.contains('3') && !d.contains('6') && !d.contains('12')) {
      return 'Monthly';
    } else if (d.contains('3') || d.contains('quarter')) {
      return 'Quarterly';
    } else if (d.contains('6')) {
      return '6 Months';
    } else if (d.contains('12') || d.contains('year') || d.contains('annual')) {
      return 'Annual';
    }
    return duration;
  }

  String _formatPrice(double price, String currency) {
    final symbol = currency.toUpperCase() == 'USD' ? '\$' : currency.toUpperCase();
    return '$symbol${price.toStringAsFixed(2)}';
  }

  bool _hasDiscount(SubPlan offer) {
    // Check if this offer has a discount compared to monthly
    final monthlyOffer = offers.firstWhere(
      (o) => o.duration?.toLowerCase().contains('month') == true &&
          !o.duration!.toLowerCase().contains('3') &&
          !o.duration!.toLowerCase().contains('6') &&
          !o.duration!.toLowerCase().contains('12'),
      orElse: () => offers.first,
    );

    if (offer.id == monthlyOffer.id) return false;

    // Calculate expected price if no discount
    final monthlyPrice = monthlyOffer.price;
    final months = _getMonths(offer.duration);
    final expectedPrice = monthlyPrice * months;

    return offer.price < expectedPrice;
  }

  double _getOriginalPrice(SubPlan offer, List<SubPlan> allOffers) {
    final monthlyOffer = allOffers.firstWhere(
      (o) => o.duration?.toLowerCase().contains('month') == true &&
          !o.duration!.toLowerCase().contains('3') &&
          !o.duration!.toLowerCase().contains('6') &&
          !o.duration!.toLowerCase().contains('12'),
      orElse: () => allOffers.first,
    );

    final months = _getMonths(offer.duration);
    return monthlyOffer.price * months;
  }

  double _calculateSavings(SubPlan offer, List<SubPlan> allOffers) {
    if (!_hasDiscount(offer)) return 0;
    final originalPrice = _getOriginalPrice(offer, allOffers);
    return originalPrice - offer.price;
  }

  double _getPerMonthPrice(SubPlan offer) {
    final months = _getMonths(offer.duration);
    if (months == 0) return offer.price;
    return offer.price / months;
  }

  int _getMonths(String? duration) {
    if (duration == null) return 1;
    final d = duration.toLowerCase();
    if (d.contains('month') && !d.contains('3') && !d.contains('6') && !d.contains('12')) {
      return 1;
    } else if (d.contains('3') || d.contains('quarter')) {
      return 3;
    } else if (d.contains('6')) {
      return 6;
    } else if (d.contains('12') || d.contains('year') || d.contains('annual')) {
      return 12;
    }
    return 1;
  }
}
