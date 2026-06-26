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
import '../shared/models/user_tier.dart';
import '../shared/analytics/app_event_tracker.dart';
import '../widgets/buttons/gradient_button.dart';

class FeatureLockedScreen extends StatelessWidget {
  final String featureTitle;
  final String? featureDescription;
  final UserTier minTier;

  const FeatureLockedScreen({
    super.key,
    required this.featureTitle,
    required this.minTier,
    this.featureDescription,
  });

  static UserTier _parseTier(String? value) {
    final v = (value ?? '').toLowerCase().trim();
    if (v == 'golden' || v == 'gold') return UserTier.golden;
    if (v == 'silder' || v == 'silver' || v == 'premium') {
      return UserTier.silder;
    }
    return UserTier.basid;
  }

  static FeatureLockedScreen fromQueryParams(Map<String, String> qp) {
    final title = qp['title']?.trim();
    final description = qp['desc']?.trim();
    final min = _parseTier(qp['minTier']);
    return FeatureLockedScreen(
      featureTitle: title?.isNotEmpty == true ? title! : 'Premium feature',
      featureDescription: description?.isNotEmpty == true ? description : null,
      minTier: min,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    final tierLabel = switch (minTier) {
      UserTier.basid => 'Basid',
      UserTier.silder => 'Silder',
      UserTier.golden => 'Golden',
    };

    return Consumer(
      builder: (context, ref, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appEventTrackerProvider).track(
            'paywall_view',
            meta: {
              'screen': 'feature_locked',
              'feature': featureTitle,
              'min_tier': minTier.key,
            },
          );
        });

        return PremiumDetailScaffold(
          title: 'Upgrade required',
          subtitle: 'Unlock premium features',
          onBack: () => context.pop(),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.radiusMD),
                            ),
                            child: Center(
                              child: AppSvgIcon(
                                assetPath: AppIcons.crown,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacingMD),
                          Expanded(
                            child: Text(
                              featureTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (featureDescription != null) ...[
                        const SizedBox(height: AppSpacing.spacingMD),
                        Text(
                          featureDescription!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.spacingMD),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingMD,
                          vertical: AppSpacing.spacingSM,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentViolet.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Required tier: $tierLabel',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.accentViolet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingXL),
                PremiumSettingsGroup(
                  title: 'Upgrade to unlock',
                  children: const [
                    _BenefitRow(text: 'See who liked you'),
                    _BenefitRow(text: 'Advanced filters'),
                    _BenefitRow(text: 'Boosts and superlikes'),
                    _BenefitRow(text: 'More control + better matches'),
                  ],
                ),
              ],
            ),
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
                      'paywall_cta',
                      meta: {
                        'cta': 'view_plans',
                        'feature': featureTitle,
                        'min_tier': minTier.key,
                      },
                    );
                    context.push(AppRoutes.subscriptionPlans);
                  },
                  isFullWidth: true,
                ),
                const SizedBox(height: AppSpacing.spacingMD),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.tierComparison),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentViolet,
                    side: BorderSide(
                      color: AppColors.accentViolet.withValues(
                        alpha: isDark ? 0.45 : 0.35,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.spacingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    ),
                  ),
                  child: Text(
                    'Compare tiers',
                    style: AppTypography.button.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(appEventTrackerProvider).track(
                      'paywall_dismiss',
                      meta: {
                        'feature': featureTitle,
                        'min_tier': minTier.key,
                      },
                    );
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: AppSvgIcon(
              assetPath: AppIcons.tickCircle,
              size: 18,
              color: AppColors.onlineGreen,
            ),
          ),
          const SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
