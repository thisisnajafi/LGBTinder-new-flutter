import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../providers/marketing_providers.dart';
import '../../data/models/campaign_model.dart';
import '../widgets/promo_code_input.dart';

/// Purchase flow promo integration
/// Part of the Marketing System Implementation (Task 3.6.4)
/// 
/// Usage in checkout screen:
/// ```dart
/// PurchasePromoSection(
///   productId: 'gold_monthly',
///   onPromoApplied: (result) {
///     setState(() => _appliedPromo = result);
///   },
/// )
/// ```
class PurchasePromoSection extends ConsumerStatefulWidget {
  final String? productId;
  final String? initialPromoCode;
  final ValueChanged<PromoValidationResult>? onPromoApplied;
  final ValueChanged<double>? onDiscountCalculated;

  const PurchasePromoSection({
    Key? key,
    this.productId,
    this.initialPromoCode,
    this.onPromoApplied,
    this.onDiscountCalculated,
  }) : super(key: key);

  @override
  ConsumerState<PurchasePromoSection> createState() => _PurchasePromoSectionState();
}

class _PurchasePromoSectionState extends ConsumerState<PurchasePromoSection> {
  bool _showPromoInput = false;
  PromoValidationResult? _appliedPromo;

  @override
  void initState() {
    super.initState();
    if (widget.initialPromoCode != null) {
      _showPromoInput = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final promotionsAsync = ref.watch(activePromotionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active promotions banner
        promotionsAsync.maybeWhen(
          data: (promotions) {
            final applicable = promotions.where((p) =>
                widget.productId == null ||
                p.applicableProducts.isEmpty ||
                p.applicableProducts.contains(widget.productId)).toList();

            if (applicable.isEmpty) return const SizedBox.shrink();

            return _buildActivePromotionsBanner(applicable);
          },
          orElse: () => const SizedBox.shrink(),
        ),

        SizedBox(height: AppSpacing.spacingMD),

        // Promo code section
        if (!_showPromoInput && _appliedPromo == null)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showPromoInput = true),
              icon: const Icon(Icons.local_offer_outlined, size: 18),
              label: const Text('Have a promo code?'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentPurple,
              ),
            ),
          )
        else if (_appliedPromo != null && _appliedPromo!.isValid)
          _buildAppliedPromo()
        else
          PromoCodeInput(
            productId: widget.productId,
            initialCode: widget.initialPromoCode,
            onValidated: (result) {
              setState(() => _appliedPromo = result);
              widget.onPromoApplied?.call(result);
            },
          ),
      ],
    );
  }

  Widget _buildActivePromotionsBanner(List<PromotionModel> promotions) {
    final theme = Theme.of(context);
    final promo = promotions.first;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple.withOpacity(0.1),
            AppColors.accentGradientEnd.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_offer, color: Colors.white, size: 20),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPurple,
                  ),
                ),
                if (promo.description != null)
                  Text(
                    promo.description!,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (promo.code != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentPurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                promo.code!,
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppliedPromo() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.onlineGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: AppColors.onlineGreen),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.onlineGreen),
          SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promo Applied!',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onlineGreen,
                  ),
                ),
                _buildDiscountText(),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _appliedPromo = null;
                _showPromoInput = true;
              });
              widget.onPromoApplied?.call(PromoValidationResult(isValid: false));
            },
            icon: const Icon(Icons.close, color: AppColors.onlineGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountText() {
    if (_appliedPromo == null) return const SizedBox.shrink();

    final parts = <String>[];

    if (_appliedPromo!.discountPercentage != null && _appliedPromo!.discountPercentage! > 0) {
      parts.add('${_appliedPromo!.discountPercentage!.toInt()}% off');
    }

    if (_appliedPromo!.discountAmount != null && _appliedPromo!.discountAmount! > 0) {
      parts.add('\$${_appliedPromo!.discountAmount!.toStringAsFixed(2)} off');
    }

    if (_appliedPromo!.bonusItems != null && _appliedPromo!.bonusItems!.isNotEmpty) {
      parts.add('+ ${_appliedPromo!.bonusItems!.length} bonus items');
    }

    return Text(
      parts.join(' • '),
      style: AppTypography.caption.copyWith(
        color: AppColors.onlineGreen,
      ),
    );
  }
}

/// Price display with original/discounted price
/// Usage:
/// ```dart
/// PriceDisplay(
///   originalPrice: 19.99,
///   discountedPrice: 14.99,
///   period: 'month',
/// )
/// ```
class PriceDisplay extends StatelessWidget {
  final double originalPrice;
  final double? discountedPrice;
  final String? period;
  final String currency;
  final bool large;

  const PriceDisplay({
    Key? key,
    required this.originalPrice,
    this.discountedPrice,
    this.period,
    this.currency = '\$',
    this.large = false,
  }) : super(key: key);

  bool get hasDiscount =>
      discountedPrice != null && discountedPrice! < originalPrice;

  double get savingsPercent =>
      hasDiscount ? ((originalPrice - discountedPrice!) / originalPrice * 100) : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final displayPrice = hasDiscount ? discountedPrice! : originalPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Original price (crossed out if discounted)
        if (hasDiscount) ...[
          Text(
            '$currency${originalPrice.toStringAsFixed(2)}',
            style: (large ? AppTypography.body : AppTypography.caption).copyWith(
              color: secondaryTextColor,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          SizedBox(width: AppSpacing.spacingSM),
        ],

        // Current price
        Text(
          '$currency${displayPrice.toStringAsFixed(2)}',
          style: (large ? AppTypography.h2 : AppTypography.h4).copyWith(
            color: hasDiscount ? AppColors.onlineGreen : textColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Period
        if (period != null) ...[
          Text(
            '/$period',
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
        ],

        // Savings badge
        if (hasDiscount) ...[
          SizedBox(width: AppSpacing.spacingMD),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.onlineGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'SAVE ${savingsPercent.toInt()}%',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Order summary with promo applied
class OrderSummary extends StatelessWidget {
  final String planName;
  final double originalPrice;
  final PromoValidationResult? promo;
  final String? period;

  const OrderSummary({
    Key? key,
    required this.planName,
    required this.originalPrice,
    this.promo,
    this.period,
  }) : super(key: key);

  double get discountAmount {
    if (promo == null || !promo!.isValid) return 0;

    if (promo!.discountPercentage != null) {
      return originalPrice * promo!.discountPercentage! / 100;
    }

    if (promo!.discountAmount != null) {
      return promo!.discountAmount!.clamp(0, originalPrice);
    }

    return 0;
  }

  double get finalPrice => originalPrice - discountAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTypography.h4.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),

          // Plan
          _buildRow(planName, '\$${originalPrice.toStringAsFixed(2)}'),

          // Discount
          if (promo != null && promo!.isValid && discountAmount > 0) ...[
            SizedBox(height: AppSpacing.spacingSM),
            _buildRow(
              'Discount (${promo!.promoCode})',
              '-\$${discountAmount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],

          // Bonus items
          if (promo != null && promo!.bonusItems != null && promo!.bonusItems!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.spacingSM),
            ...promo!.bonusItems!.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard, size: 14, color: AppColors.accentYellow),
                      SizedBox(width: 6),
                      Text(
                        item,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentYellow,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'FREE',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          Divider(height: AppSpacing.spacingLG * 2),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total${period != null ? ' (per $period)' : ''}',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                '\$${finalPrice.toStringAsFixed(2)}',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: discountAmount > 0 ? AppColors.onlineGreen : textColor,
                ),
              ),
            ],
          ),

          // Savings
          if (discountAmount > 0) ...[
            SizedBox(height: AppSpacing.spacingXS),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'You save \$${discountAmount.toStringAsFixed(2)}!',
                style: AppTypography.caption.copyWith(
                  color: AppColors.onlineGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: isDiscount ? AppColors.onlineGreen : null,
            fontWeight: isDiscount ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}
