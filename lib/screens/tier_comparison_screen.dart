import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/subscription_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../features/payments/data/models/subscription_plan.dart';
import '../features/payments/providers/payment_providers.dart';
import '../routes/app_router.dart';
import '../shared/analytics/app_event_tracker.dart';
import '../shared/models/user_tier.dart';
import '../widgets/buttons/gradient_button.dart';
import '../core/responsive/responsive.dart';

/// One row of the Compare tiers page. Feature lists mirror what the backend
/// enforces (PlanLimitsController / SubscriptionFeatures / PlanLimitSettings).
class TierComparisonCard {
  const TierComparisonCard({
    required this.tier,
    required this.title,
    required this.tagline,
    required this.accent,
    required this.bullets,
  });

  /// null = Free (no subscription).
  final UserTier? tier;
  final String title;
  final String tagline;
  final Color accent;
  final List<String> bullets;
}

const tierComparisonCards = <TierComparisonCard>[
  TierComparisonCard(
    tier: null,
    title: 'Free',
    tagline: 'Get started',
    accent: AppColors.accentViolet,
    bullets: [
      'Discovery and swiping with daily limits',
      'Daily message limits per match',
      '1 Super Like per day',
    ],
  ),
  TierComparisonCard(
    tier: UserTier.basid,
    title: 'Basic',
    tagline: 'Chat without limits',
    accent: AppColors.accentViolet,
    bullets: [
      'Unlimited chat with your matches',
      'Full message history',
      'Ad-free',
    ],
  ),
  TierComparisonCard(
    tier: UserTier.silder,
    title: 'Premium',
    tagline: 'Best for faster matches',
    accent: AppColors.accentPink,
    bullets: [
      'Everything in Basic',
      'Voice calls',
      'See who liked you',
      'Advanced filters, Passport and Rewind',
      'Unlimited swipes and 5 Super Likes per day',
    ],
  ),
  TierComparisonCard(
    tier: UserTier.golden,
    title: 'Gold',
    tagline: 'Everything unlocked',
    accent: AppColors.feedbackWarning,
    bullets: [
      'Everything in Premium',
      'Video calls',
      'AI matching',
      '10 Super Likes per day',
    ],
  ),
];

class TierComparisonScreen extends StatelessWidget {
  const TierComparisonScreen({super.key});

  String _priceFor(List<SubscriptionPlan> plans, UserTier tier) {
    for (final plan in plans) {
      final name = plan.name.toLowerCase();
      final hits = switch (tier) {
        UserTier.basid => plan.id == 1 || name.contains('basic') || name.contains('bronze'),
        UserTier.silder => plan.id == 2 ||
            name.contains('premium') ||
            name.contains('silver') ||
            name.contains('silder'),
        UserTier.golden => plan.id == 3 || name.contains('gold'),
      };
      if (hits) {
        final amount = plan.price.toStringAsFixed(
          plan.price == plan.price.roundToDouble() ? 0 : 2,
        );
        return '${plan.currency.toUpperCase()} $amount';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Consumer(
      builder: (context, ref, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appEventTrackerProvider).track(
            'tier_compare_view',
            meta: {'screen': 'tier_comparison'},
          );
        });

        final sub = ref.watch(subscriptionProvider);
        // null = Free (no active subscription).
        final UserTier? currentTier =
            sub != null && sub.isActive ? sub.tier : null;
        final plans = ref.watch(subscriptionPlansProvider).valueOrNull ??
            const <SubscriptionPlan>[];

        return PremiumDetailScaffold(
          title: 'Compare tiers',
          subtitle: 'Choose the plan that fits you',
          onBack: () => context.pop(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacingLG,
              0,
              AppSpacing.spacingLG,
              AppSpacing.spacingMD,
            ),
            children: [
              AppText(
                'Current plan: ${currentTier?.displayLabel ?? 'Free'}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.spacingMD),
              Text(
                'Upgrade anytime. Your benefits update instantly.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              for (final card in tierComparisonCards) ...[
                _TierCard(
                  title: card.title,
                  subtitle: card.tier == null
                      ? 'No subscription'
                      : (_priceFor(plans, card.tier!).isEmpty
                          ? card.tagline
                          : '${_priceFor(plans, card.tier!)} / month'),
                  accent: card.accent,
                  highlight: card.tier == UserTier.silder &&
                      currentTier != UserTier.golden,
                  isCurrent: card.tier == currentTier,
                  bullets: card.bullets,
                ),
                const SizedBox(height: AppSpacing.spacingLG),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.spacingLG,
              AppSpacing.spacingSM,
              AppSpacing.spacingLG,
              AppSpacing.spacingLG,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradientButton(
                  text: 'View plans',
                  iconPath: AppIcons.crown,
                  onPressed: () {
                    ref.read(appEventTrackerProvider).track(
                      'tier_compare_cta',
                      meta: {'cta': 'view_plans'},
                    );
                    context.push(AppRoutes.subscriptionPlans);
                  },
                  isFullWidth: true,
                ),
                TextButton(
                  onPressed: () {
                    ref.read(appEventTrackerProvider).track('tier_compare_dismiss');
                    context.pop();
                  },
                  child: Text(
                    'Not now',
                    style: AppTypography.button.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.accent,
    this.highlight = false,
    this.isCurrent = false,
  });

  final String title;
  final String subtitle;
  final List<String> bullets;
  final Color accent;
  final bool highlight;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isCurrent ? theme.colorScheme.primary : accent;

    return Container(
      decoration: (highlight || isCurrent)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusLG),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            )
          : null,
      child: PremiumShell(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingSM,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    ),
                    child: Text(
                      'Current',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingSM,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, AppColors.accentViolet],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                    ),
                    child: Text(
                      'Recommended',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXS),
            AppText(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.checkCircle,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    Expanded(
                      child: AppText(
                        bullet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                        ),
                        maxLines: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
