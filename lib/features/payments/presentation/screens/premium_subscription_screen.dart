// Screen: Premium Subscription Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../providers/payment_providers.dart';
import '../../../../core/providers/feature_flags_provider.dart';
import 'subscription_plans_screen.dart';
import 'superlike_packs_screen.dart';
import 'subscription_management_screen.dart';

/// Premium Subscription Screen - Landing page for premium features
class PremiumSubscriptionScreen extends ConsumerWidget {
  const PremiumSubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final subscriptionStatusAsync = ref.watch(subscriptionStatusProvider);
    final paymentSystem = ref.watch(activePaymentSystemProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Premium',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Unlock Premium',
              style: AppTypography.h1.copyWith(color: textColor),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Get the most out of LGBTFinder with premium features',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            ),

            SizedBox(height: AppSpacing.spacingXXL),

            // Current Subscription Status
            subscriptionStatusAsync.when(
              data: (status) {
                if (status?.isActive == true) {
                  return Container(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    decoration: BoxDecoration(
                      color: AppColors.onlineGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                      border: Border.all(color: AppColors.onlineGreen),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.onlineGreen,
                              size: 24,
                            ),
                            SizedBox(width: AppSpacing.spacingSM),
                            Text(
                              'Premium Active',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.onlineGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.spacingSM),
                        Text(
                          'Plan: ${status?.planName ?? 'Premium'}',
                          style: AppTypography.body.copyWith(color: textColor),
                        ),
                        SizedBox(height: AppSpacing.spacingSM),
                        GradientButton(
                          text: 'Manage Subscription',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionManagementScreen(),
                              ),
                            );
                          },
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    padding: EdgeInsets.all(AppSpacing.spacingLG),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentPurple.withOpacity(0.1), AppColors.accentPink.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                      border: Border.all(
                        color: AppColors.accentPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              color: AppColors.accentPurple,
                              size: 24,
                            ),
                            SizedBox(width: AppSpacing.spacingSM),
                            Text(
                              'Upgrade to Premium',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.accentPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.spacingSM),
                        Text(
                          'Unlock unlimited matches, superlikes, and premium features',
                          style: AppTypography.body.copyWith(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  );
                }
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  border: Border.all(color: AppColors.accentRed),
                ),
                child: Text(
                  'Unable to load subscription status',
                  style: AppTypography.body.copyWith(color: AppColors.accentRed),
                ),
              ),
            ),

            SizedBox(height: AppSpacing.spacingXXL),

            // Premium Features
            Text(
              'Premium Features',
              style: AppTypography.h2.copyWith(color: textColor),
            ),
            SizedBox(height: AppSpacing.spacingLG),

            _buildFeatureCard(
              icon: Icons.visibility,
              title: 'See Who Likes You',
              description: 'View profiles of people who liked you before matching',
              surfaceColor: surfaceColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),

            _buildFeatureCard(
              icon: Icons.favorite,
              title: 'Unlimited Superlikes',
              description: 'Send unlimited superlikes to show special interest',
              surfaceColor: surfaceColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),

            _buildFeatureCard(
              icon: Icons.rewind,
              title: 'Unlimited Rewinds',
              description: 'Go back and reconsider your decisions',
              surfaceColor: surfaceColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),

            _buildFeatureCard(
              icon: Icons.location_on,
              title: 'Passport',
              description: 'Match with people anywhere in the world',
              surfaceColor: surfaceColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),

            SizedBox(height: AppSpacing.spacingXXL),

            // Action Buttons
            GradientButton(
              text: subscriptionStatusAsync.value?.isActive == true
                  ? 'View Subscription Plans'
                  : 'View Subscription Plans',
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

            SizedBox(height: AppSpacing.spacingLG),

            // Superlike Packs Button
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuperlikePacksScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accentPink),
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppColors.accentPink,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Text(
                    'Buy Superlike Packs',
                    style: AppTypography.button.copyWith(
                      color: AppColors.accentPink,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.spacingXXL),

            // Payment System Info
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: secondaryTextColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: secondaryTextColor,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: Text(
                      'Payments processed securely via ${paymentSystem.displayName}',
                      style: AppTypography.caption.copyWith(color: secondaryTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color surfaceColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingMD),
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingSM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentPurple, AppColors.accentPink],
              ),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.spacingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.spacingXS),
                Text(
                  description,
                  style: AppTypography.body.copyWith(color: secondaryTextColor),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: secondaryTextColor,
          ),
        ],
      ),
    );
  }
}
