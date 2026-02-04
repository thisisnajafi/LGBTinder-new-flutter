// Screen: PremiumSubscriptionScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/premium/premium_feature_card.dart';
import '../../widgets/badges/premium_badge.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';
import '../../core/constants/api_endpoints.dart';
import '../premium_features_screen.dart';

/// Premium subscription screen - Subscribe to premium plans
class PremiumSubscriptionScreen extends ConsumerStatefulWidget {
  const PremiumSubscriptionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends ConsumerState<PremiumSubscriptionScreen> {
  String? _selectedPlan;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'monthly',
      'name': 'Monthly',
      'price': 9.99,
      'period': 'month',
      'savings': null,
      'popular': false,
    },
    {
      'id': 'quarterly',
      'name': 'Quarterly',
      'price': 24.99,
      'period': '3 months',
      'savings': 17,
      'popular': true,
    },
    {
      'id': 'yearly',
      'name': 'Yearly',
      'price': 79.99,
      'period': 'year',
      'savings': 40,
      'popular': false,
    },
  ];

  Future<void> _handleSubscribe() async {
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
      // Map plan IDs to database sub_plan_ids
      // This would need to be updated based on actual database plan IDs
      final planIdMap = {
        'monthly': 1,   // Assuming monthly plan has ID 1 in database
        'quarterly': 2, // Assuming quarterly plan has ID 2 in database
        'yearly': 3,    // Assuming yearly plan has ID 3 in database
      };

      final subPlanId = planIdMap[planId] ?? 1; // Default to monthly plan

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post<Map<String, dynamic>>(
        ApiEndpoints.subscriptionsSubscribe,
        data: {
          'plan_id': subPlanId,
          'sub_plan_id': subPlanId,
          'currency': 'usd',
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        if (mounted) {
          AlertDialogCustom.show(
            context,
            title: 'Premium Subscription Activated!',
            message: 'Your premium subscription is now active. Enjoy all premium features!',
            icon: Icons.star,
            iconColor: AppColors.primaryLight,
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process subscription: $e')),
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
        title: 'Premium Subscription',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingXXL),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Column(
              children: [
                PremiumBadge(isPremium: true, fontSize: 16),
                SizedBox(height: AppSpacing.spacingMD),
                Text(
                  'Upgrade to Premium',
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  'Unlock all features and get more matches',
                  style: AppTypography.body.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),

          // Subscription plans
          SectionHeader(
            title: 'Choose Your Plan',
            icon: Icons.credit_card,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ..._plans.map((plan) {
            final isSelected = _selectedPlan == plan['id'];
            final isPopular = plan['popular'] == true;
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
                  child: Row(
                    children: [
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
                      SizedBox(width: AppSpacing.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  plan['name'],
                                  style: AppTypography.h3.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
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
                            SizedBox(height: AppSpacing.spacingXS),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${plan['price']}',
                                  style: AppTypography.h1.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.spacingXS),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '/${plan['period']}',
                                    style: AppTypography.body.copyWith(
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (plan['savings'] != null) ...[
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
                    ],
                  ),
                ),
              ),
            );
          }),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Features reminder
          SectionHeader(
            title: 'Premium Features',
            icon: Icons.star,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          PremiumFeatureCard(
            title: 'Unlimited Likes',
            description: 'Like as many profiles as you want',
            icon: Icons.favorite,
            isUnlocked: false,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          PremiumFeatureCard(
            title: 'See Who Liked You',
            description: 'View everyone who has liked your profile',
            icon: Icons.visibility,
            isUnlocked: false,
          ),
          SizedBox(height: AppSpacing.spacingSM),
          PremiumFeatureCard(
            title: 'No Ads',
            description: 'Enjoy an ad-free experience',
            icon: Icons.block,
            isUnlocked: false,
          ),
          SizedBox(height: AppSpacing.spacingXXL),

          // Subscribe button
          GradientButton(
            text: _isLoading ? 'Processing...' : 'Subscribe Now',
            onPressed: _isLoading ? null : _handleSubscribe,
            isLoading: _isLoading,
            isFullWidth: true,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Cancel anytime. Subscription will auto-renew unless cancelled.',
            style: AppTypography.caption.copyWith(
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }
}
