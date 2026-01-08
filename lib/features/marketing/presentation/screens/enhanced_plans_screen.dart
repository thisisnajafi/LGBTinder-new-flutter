import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../../../widgets/loading/skeleton_loading.dart';
import '../../../payments/providers/payment_providers.dart';
import '../../../payments/data/models/subscription_plan.dart';
import '../../providers/marketing_providers.dart';
import '../../data/models/campaign_model.dart';
import '../widgets/promo_code_input.dart';
import '../widgets/promotional_banner.dart';

/// Enhanced subscription plans screen with marketing features
/// Part of the Marketing System Implementation (Task 3.5.1)
/// 
/// Features:
/// - Diamond tier support
/// - Price anchoring layout (Diamond first)
/// - "Most Popular" badge
/// - Value stacking display
/// - Promo code input
/// - Dynamic pricing integration
/// - Promotional banners
class EnhancedPlansScreen extends ConsumerStatefulWidget {
  final String? promoCode;

  const EnhancedPlansScreen({
    Key? key,
    this.promoCode,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedPlansScreen> createState() => _EnhancedPlansScreenState();
}

class _EnhancedPlansScreenState extends ConsumerState<EnhancedPlansScreen> {
  bool _isLoading = false;
  List<SubscriptionPlan> _plans = [];
  int? _selectedPlanId;
  PromoValidationResult? _appliedPromo;
  bool _showPromoInput = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();

    // Auto-apply promo code if provided
    if (widget.promoCode != null && widget.promoCode!.isNotEmpty) {
      _showPromoInput = true;
    }
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final plans = await paymentService.getPlans();

      if (mounted) {
        setState(() {
          // Sort plans by price descending (Diamond first - price anchoring)
          _plans = List.from(plans)
            ..sort((a, b) => (b.basePrice ?? 0).compareTo(a.basePrice ?? 0));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onPromoValidated(PromoValidationResult result) {
    setState(() {
      _appliedPromo = result;
    });
  }

  double _getDiscountedPrice(double originalPrice) {
    if (_appliedPromo == null || !_appliedPromo!.isValid) {
      return originalPrice;
    }

    if (_appliedPromo!.discountPercentage != null) {
      return originalPrice * (1 - _appliedPromo!.discountPercentage! / 100);
    }

    if (_appliedPromo!.discountAmount != null) {
      return (originalPrice - _appliedPromo!.discountAmount!).clamp(0, originalPrice);
    }

    return originalPrice;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Get banners for plans screen
    final bannersAsync = ref.watch(bannersByPositionProvider('plans'));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Choose Your Plan',
        showBackButton: true,
      ),
      body: _isLoading
          ? const SkeletonLoading()
          : RefreshIndicator(
              onRefresh: _loadPlans,
              child: ListView(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                children: [
                  // Hero Banner
                  bannersAsync.maybeWhen(
                    data: (banners) {
                      final heroBanner = banners.firstWhere(
                        (b) => b.bannerType == 'hero',
                        orElse: () => banners.isNotEmpty ? banners.first : null as dynamic,
                      );
                      if (heroBanner != null) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.spacingLG),
                          child: PromotionalBanner(banner: heroBanner),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // Header
                  Text(
                    'Unlock Premium Features',
                    style: AppTypography.h2.copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.spacingSM),
                  Text(
                    'Choose the plan that fits your needs',
                    style: AppTypography.body.copyWith(color: secondaryTextColor),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppSpacing.spacingXL),

                  // Promo code toggle
                  if (!_showPromoInput)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _showPromoInput = true),
                        icon: const Icon(Icons.local_offer_outlined, size: 18),
                        label: const Text('Have a promo code?'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentPurple,
                        ),
                      ),
                    ),

                  // Promo code input
                  if (_showPromoInput) ...[
                    PromoCodeInput(
                      initialCode: widget.promoCode,
                      onValidated: _onPromoValidated,
                    ),
                    SizedBox(height: AppSpacing.spacingLG),
                  ],

                  // Plans grid
                  ..._plans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    return _buildPlanCard(
                      context,
                      plan,
                      isFirst: index == 0,
                      isPopular: plan.isPopular,
                    );
                  }),

                  SizedBox(height: AppSpacing.spacingXL),

                  // Subscribe button
                  if (_selectedPlanId != null) ...[
                    GradientButton(
                      text: _appliedPromo?.isValid == true
                          ? 'Subscribe with Discount'
                          : 'Subscribe Now',
                      onPressed: _subscribe,
                      isFullWidth: true,
                    ),
                    SizedBox(height: AppSpacing.spacingMD),
                  ],

                  // Terms
                  Text(
                    'Subscriptions auto-renew until cancelled. Cancel anytime.',
                    style: AppTypography.caption.copyWith(
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan, {
    bool isFirst = false,
    bool isPopular = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    final isSelected = _selectedPlanId == plan.id;
    final originalPrice = plan.basePrice ?? 0;
    final discountedPrice = _getDiscountedPrice(originalPrice);
    final hasDiscount = discountedPrice < originalPrice;

    // Determine tier color
    Color tierColor;
    String tierName = plan.name.toLowerCase();
    switch (tierName) {
      case 'diamond':
        tierColor = const Color(0xFFB9F2FF); // Diamond blue
        break;
      case 'gold':
        tierColor = const Color(0xFFFFD700); // Gold
        break;
      case 'silver':
        tierColor = const Color(0xFFC0C0C0); // Silver
        break;
      default:
        tierColor = const Color(0xFFCD7F32); // Bronze
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingLG),
      decoration: BoxDecoration(
        gradient: isFirst
            ? LinearGradient(
                colors: [
                  tierColor.withOpacity(0.3),
                  tierColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFirst ? null : (isSelected ? AppColors.accentPurple.withOpacity(0.1) : surfaceColor),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: isSelected
              ? AppColors.accentPurple
              : isFirst
                  ? tierColor
                  : borderColor,
          width: isSelected || isFirst ? 2 : 1,
        ),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: tierColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPlanId = plan.id),
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Tier icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tierColor, tierColor.withOpacity(0.7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTierIcon(tierName),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: AppSpacing.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: AppTypography.h3.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (plan.description != null)
                                Text(
                                  plan.description!,
                                  style: AppTypography.caption.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Selection indicator
                        Radio<int>(
                          value: plan.id,
                          groupValue: _selectedPlanId,
                          onChanged: (v) => setState(() => _selectedPlanId = v),
                          activeColor: AppColors.accentPurple,
                        ),
                      ],
                    ),

                    SizedBox(height: AppSpacing.spacingLG),

                    // Price section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: AppTypography.body.copyWith(
                              color: secondaryTextColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: AppSpacing.spacingSM),
                        ],
                        Text(
                          '\$${discountedPrice.toStringAsFixed(2)}',
                          style: AppTypography.h2.copyWith(
                            color: hasDiscount ? AppColors.onlineGreen : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/month',
                          style: AppTypography.body.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        const Spacer(),
                        if (hasDiscount)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacingSM,
                              vertical: AppSpacing.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.onlineGreen,
                              borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                            ),
                            child: Text(
                              'SAVE ${(((originalPrice - discountedPrice) / originalPrice) * 100).toInt()}%',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: AppSpacing.spacingLG),

                    // Value stacking - Features
                    if (plan.features != null && plan.features!.isNotEmpty) ...[
                      Text(
                        'What\'s included:',
                        style: AppTypography.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.spacingSM),
                      ...plan.features!.take(5).map((feature) => Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.spacingXS),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: AppColors.onlineGreen,
                                ),
                                SizedBox(width: AppSpacing.spacingSM),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: AppTypography.body.copyWith(
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (plan.features!.length > 5)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.spacingXS),
                          child: Text(
                            '+${plan.features!.length - 5} more features',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],

                    // Bonus items from promo
                    if (_appliedPromo?.isValid == true &&
                        _appliedPromo!.bonusItems != null &&
                        _appliedPromo!.bonusItems!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.spacingMD),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.spacingMD),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          border: Border.all(
                            color: AppColors.accentYellow.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  size: 18,
                                  color: AppColors.accentYellow,
                                ),
                                SizedBox(width: AppSpacing.spacingSM),
                                Text(
                                  'Bonus Items',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.accentYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.spacingSM),
                            ..._appliedPromo!.bonusItems!.map((item) => Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star, size: 14, color: AppColors.accentYellow),
                                      SizedBox(width: 6),
                                      Text(item, style: AppTypography.caption),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Popular badge
              if (isPopular)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    ),
                    child: Text(
                      'MOST POPULAR',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

              // Best value badge (for first/highest tier)
              if (isFirst && !isPopular)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor,
                      borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                    ),
                    child: Text(
                      'BEST VALUE',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond':
        return Icons.diamond;
      case 'gold':
        return Icons.workspace_premium;
      case 'silver':
        return Icons.star;
      default:
        return Icons.shield;
    }
  }

  Future<void> _subscribe() async {
    if (_selectedPlanId == null) return;

    // Navigate to checkout with promo code if applied
    final promoCode = _appliedPromo?.isValid == true ? _appliedPromo!.promoCode : null;
    context.push('/checkout/$_selectedPlanId${promoCode != null ? '?promo=$promoCode' : ''}');
  }
}
