// Screen: SubscriptionPlansScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../widgets/navbar/app_bar_custom.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/badges/premium_badge.dart';
import '../widgets/modals/alert_dialog_custom.dart';
import 'premium/premium_subscription_screen.dart';

/// Subscription plans screen - View and select subscription plans
class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  String? _selectedPlan;
  bool _isLoading = false;
  String _billingCycle = 'monthly'; // 'monthly' or 'yearly'

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'basic',
      'name': 'Basic',
      'monthly_price': 9.99,
      'yearly_price': 99.99,
      'features': [
        'Unlimited likes',
        '5 Superlikes per day',
        '1 Boost per month',
        'See who liked you',
      ],
      'popular': false,
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'monthly_price': 19.99,
      'yearly_price': 199.99,
      'features': [
        'Everything in Basic',
        'Unlimited Superlikes',
        '5 Boosts per month',
        'See who liked you',
        'Read receipts',
        'No ads',
        'Passport (change location)',
        'Rewind (undo swipes)',
      ],
      'popular': true,
      'savings': 17,
    },
    {
      'id': 'platinum',
      'name': 'Platinum',
      'monthly_price': 29.99,
      'yearly_price': 299.99,
      'features': [
        'Everything in Premium',
        'Unlimited Boosts',
        'Priority likes',
        'Message before matching',
        'See likes you\'ve sent',
        'Advanced filters',
        'Top Picks',
      ],
      'popular': false,
      'savings': 20,
    },
  ];

  Future<void> _handleSubscribe(String planId) async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Process subscription via API
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        final selectedPlan = _plans.firstWhere((p) => p['id'] == planId);
        AlertDialogCustom.show(
          context,
          title: 'Subscription Started!',
          message: 'You\'ve successfully subscribed to ${selectedPlan['name']}',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Subscription Plans',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Billing cycle toggle
          Container(
            margin: EdgeInsets.all(AppSpacing.spacingLG),
            padding: EdgeInsets.all(AppSpacing.spacingSM),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _billingCycle = 'monthly';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
                      decoration: BoxDecoration(
                        color: _billingCycle == 'monthly'
                            ? AppColors.accentPurple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                      child: Text(
                        'Monthly',
                        textAlign: TextAlign.center,
                        style: AppTypography.button.copyWith(
                          color: _billingCycle == 'monthly'
                              ? Colors.white
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _billingCycle = 'yearly';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
                      decoration: BoxDecoration(
                        color: _billingCycle == 'yearly'
                            ? AppColors.accentPurple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Yearly',
                            textAlign: TextAlign.center,
                            style: AppTypography.button.copyWith(
                              color: _billingCycle == 'yearly'
                                  ? Colors.white
                                  : textColor,
                            ),
                          ),
                          Text(
                            'Save up to 20%',
                            style: AppTypography.caption.copyWith(
                              color: _billingCycle == 'yearly'
                                  ? Colors.white70
                                  : AppColors.onlineGreen,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Plans list
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
              children: [
                SectionHeader(
                  title: 'Choose Your Plan',
                  icon: Icons.star,
                ),
                SizedBox(height: AppSpacing.spacingMD),
                ..._plans.map((plan) {
                  final isSelected = _selectedPlan == plan['id'];
                  final isPopular = plan['popular'] == true;
                  final price = _billingCycle == 'monthly'
                      ? plan['monthly_price']
                      : plan['yearly_price'];
                  final period = _billingCycle == 'monthly' ? 'month' : 'year';
                  final monthlyEquivalent = _billingCycle == 'yearly'
                      ? (plan['yearly_price'] / 12).toStringAsFixed(2)
                      : null;

                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlan = plan['id'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(AppSpacing.spacingLG),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentPurple
                                : (isPopular ? AppColors.accentPink : borderColor),
                            width: isSelected ? 2 : 1,
                          ),
                          gradient: isPopular
                              ? LinearGradient(
                                  colors: [
                                    AppColors.accentPink.withOpacity(0.1),
                                    AppColors.accentPurple.withOpacity(0.1),
                                  ],
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            plan['name'],
                                            style: AppTypography.h1.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (isPopular) ...[
                                            SizedBox(width: AppSpacing.spacingSM),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: AppSpacing.spacingSM,
                                                vertical: AppSpacing.spacingXS,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: AppTheme.accentGradient,
                                                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                                              ),
                                              child: Text(
                                                'POPULAR',
                                                style: AppTypography.caption.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: AppSpacing.spacingSM),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${price.toStringAsFixed(2)}',
                                            style: AppTypography.h1.copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: AppSpacing.spacingXS),
                                          Padding(
                                            padding: EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              '/$period',
                                              style: AppTypography.body.copyWith(
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (monthlyEquivalent != null) ...[
                                        SizedBox(height: AppSpacing.spacingXS),
                                        Text(
                                          '\$$monthlyEquivalent/month when billed annually',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.onlineGreen,
                                          ),
                                        ),
                                      ],
                                      if (plan['savings'] != null && _billingCycle == 'yearly') ...[
                                        SizedBox(height: AppSpacing.spacingXS),
                                        Text(
                                          'Save ${plan['savings']}%',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.onlineGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Radio<String>(
                                  value: plan['id'],
                                  groupValue: _selectedPlan,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPlan = value;
                                    });
                                  },
                                  activeColor: AppColors.accentPurple,
                                ),
                              ],
                            ),
                            DividerCustom(),
                            SizedBox(height: AppSpacing.spacingMD),
                            ...(plan['features'] as List<String>).map((feature) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.onlineGreen,
                                      size: 20,
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
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: AppSpacing.spacingXXL),
              ],
            ),
          ),
          // Subscribe button
          Padding(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            child: GradientButton(
              text: _isLoading ? 'Processing...' : 'Subscribe Now',
              onPressed: _isLoading || _selectedPlan == null
                  ? null
                  : () => _handleSubscribe(_selectedPlan!),
              isLoading: _isLoading,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
