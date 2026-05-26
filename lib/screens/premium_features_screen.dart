// Screen: PremiumFeaturesScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/widgets/app_page_scaffold.dart';
import '../core/widgets/app_page_header.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/divider_custom.dart';
import '../widgets/premium/premium_feature_card.dart';
import '../widgets/badges/premium_badge.dart';
import '../widgets/buttons/gradient_button.dart';
import '../shared/models/user_tier.dart';
import '../shared/providers/user_tier_provider.dart';
import '../routes/app_router.dart';

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
    
    final currentTier = ref.watch(userTierProvider);

    bool unlocked(UserTier minTier) => currentTier.atLeast(minTier);
    String tierLabel(UserTier tier) => switch (tier) {
          UserTier.basid => 'Basid',
          UserTier.silder => 'Silder',
          UserTier.golden => 'Golden',
        };

    final isPremium = unlocked(UserTier.silder);

    final premiumFeatures = [
      {
        'title': 'Unlimited Likes',
        'description': 'Like as many profiles as you want',
        'icon': Icons.favorite,
        'minTier': UserTier.silder,
      },
      {
        'title': 'See Who Liked You',
        'description': 'View everyone who has liked your profile',
        'icon': Icons.visibility,
        'minTier': UserTier.silder,
      },
      {
        'title': 'Super Likes',
        'description': 'Get 5 super likes per day to stand out',
        'icon': Icons.star,
        'minTier': UserTier.silder,
      },
      {
        'title': 'Rewind',
        'description': 'Undo your last swipe',
        'icon': Icons.undo,
        'minTier': UserTier.silder,
      },
      {
        'title': 'Boost',
        'description': 'Get more profile views for 30 minutes',
        'icon': Icons.trending_up,
        'minTier': UserTier.golden,
      },
      {
        'title': 'No Ads',
        'description': 'Enjoy an ad-free experience',
        'icon': Icons.block,
        'minTier': UserTier.silder,
      },
    ];

    return AppPageScaffold(
      title: 'Premium Features',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPageHeader.horizontalPadding,
        ),
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
                  isPremium
                      ? 'Your tier: ${tierLabel(currentTier)}'
                      : 'Upgrade to Premium',
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.spacingSM),
                Text(
                  isPremium
                      ? 'Some features require Golden tier'
                      : 'Unlock more features and get more matches',
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
            final minTier = feature['minTier'] as UserTier;
            final isUnlocked = unlocked(minTier);
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacingMD),
              child: PremiumFeatureCard(
                title: feature['title'] as String,
                description:
                    '${feature['description']} (Min: ${tierLabel(minTier)})',
                icon: feature['icon'] as IconData,
                isUnlocked: isUnlocked,
                onTap: () {
                  if (!isUnlocked) {
                    final target = Uri(
                      path: AppRoutes.featureLocked,
                      queryParameters: {
                        'title': feature['title'] as String,
                        'desc': feature['description'] as String,
                        'minTier': minTier.key,
                      },
                    ).toString();
                    context.push(target);
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
                context.push(AppRoutes.subscriptionPlans);
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
