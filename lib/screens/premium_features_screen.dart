// Screen: PremiumFeaturesScreen
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
import '../widgets/premium/premium_feature_card.dart';
import '../widgets/badges/premium_badge.dart';
import '../widgets/buttons/gradient_button.dart';
import '../features/payments/presentation/screens/subscription_plans_screen.dart';
import '../features/payments/providers/payment_providers.dart';
import '../features/payments/data/models/subscription_plan.dart';

/// Premium features screen - Display and manage premium features
class PremiumFeaturesScreen extends ConsumerWidget {
  const PremiumFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    
    // Get subscription status
    final subscriptionStatusAsync = ref.watch(subscriptionStatusProvider);
    final isPremium = subscriptionStatusAsync.when(
      data: (status) => status?.isActive == true,
      loading: () => false,
      error: (_, __) => false,
    );

    final premiumFeatures = [
      {
        'title': 'Unlimited Likes',
        'description': 'Like as many profiles as you want',
        'icon': Icons.favorite,
        'unlocked': isPremium,
      },
      {
        'title': 'See Who Liked You',
        'description': 'View everyone who has liked your profile',
        'icon': Icons.visibility,
        'unlocked': isPremium,
      },
      {
        'title': 'Super Likes',
        'description': 'Get 5 super likes per day to stand out',
        'icon': Icons.star,
        'unlocked': isPremium,
      },
      {
        'title': 'Rewind',
        'description': 'Undo your last swipe',
        'icon': Icons.undo,
        'unlocked': isPremium,
      },
      {
        'title': 'Boost',
        'description': 'Get more profile views for 30 minutes',
        'icon': Icons.trending_up,
        'unlocked': isPremium,
      },
      {
        'title': 'No Ads',
        'description': 'Enjoy an ad-free experience',
        'icon': Icons.block,
        'unlocked': isPremium,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Premium Features',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          // Premium header
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
                  isPremium ? 'You\'re Premium!' : 'Upgrade to Premium',
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  isPremium
                      ? 'Enjoy all premium features'
                      : 'Unlock all features and get more matches',
                  style: AppTypography.body.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.spacingXXL),

          // Features list
          SectionHeader(
            title: 'Premium Features',
            icon: Icons.star,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ...premiumFeatures.map((feature) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
              child: PremiumFeatureCard(
                title: feature['title'] as String,
                description: feature['description'] as String,
                icon: feature['icon'] as IconData,
                isUnlocked: feature['unlocked'] as bool,
                onTap: () {
                  if (!isPremium) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionPlansScreen(),
                      ),
                    );
                  }
                },
              ),
            );
          }),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Upgrade button
          if (!isPremium)
            GradientButton(
              text: 'Upgrade to Premium',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              isFullWidth: true,
            ),
          if (isPremium)
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: AppColors.onlineGreen),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.onlineGreen,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Text(
                    'You have Premium',
                    style: AppTypography.body.copyWith(
                      color: AppColors.onlineGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: AppSpacing.spacingXXL),
        ],
      ),
    );
  }
}
