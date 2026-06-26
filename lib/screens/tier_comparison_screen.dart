import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/premium/premium_design_system.dart';
import '../routes/app_router.dart';
import '../shared/analytics/app_event_tracker.dart';
import '../widgets/buttons/gradient_button.dart';

class TierComparisonScreen extends StatelessWidget {
  const TierComparisonScreen({super.key});

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

        return PremiumDetailScaffold(
          title: 'Compare tiers',
          subtitle: 'Choose the plan that fits you',
          onBack: () => context.pop(),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            children: [
              Text(
                'Upgrade anytime. Your benefits update instantly.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              _TierCard(
                title: 'Basid',
                subtitle: 'Great to start',
                accent: AppColors.accentViolet,
                bullets: const [
                  'Discovery + swiping',
                  'Basic messaging limits',
                  'Standard filters',
                ],
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              _TierCard(
                title: 'Silder',
                subtitle: 'Best for faster matches',
                accent: AppColors.accentPink,
                highlight: true,
                bullets: const [
                  'See who liked you',
                  'Advanced filters',
                  'More superlikes/boosts',
                  'More messaging freedom',
                ],
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              _TierCard(
                title: 'Golden',
                subtitle: 'Everything unlocked',
                accent: AppColors.feedbackWarning,
                bullets: const [
                  'All Silder benefits',
                  'Highest limits + priority perks',
                  'Exclusive badges/visibility boosts',
                ],
              ),
              const SizedBox(height: AppSpacing.spacingXXL),
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
  });

  final String title;
  final String subtitle;
  final List<String> bullets;
  final Color accent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: highlight
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusLG),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
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
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingSM,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, AppColors.accentViolet],
                      ),
                      borderRadius: BorderRadius.circular(99),
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
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.tickCircle,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    Expanded(
                      child: Text(
                        bullet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                        ),
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
