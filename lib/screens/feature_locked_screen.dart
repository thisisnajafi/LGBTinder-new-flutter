import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../routes/app_router.dart';
import '../shared/models/user_tier.dart';
import '../shared/analytics/app_event_tracker.dart';
import '../widgets/buttons/gradient_button.dart';
import '../widgets/navbar/app_bar_custom.dart';

class FeatureLockedScreen extends StatelessWidget {
  final String featureTitle;
  final String? featureDescription;
  final UserTier minTier;

  const FeatureLockedScreen({
    Key? key,
    required this.featureTitle,
    required this.minTier,
    this.featureDescription,
  }) : super(key: key);

  static UserTier _parseTier(String? value) {
    final v = (value ?? '').toLowerCase().trim();
    if (v == 'golden' || v == 'gold') return UserTier.golden;
    if (v == 'silder' || v == 'silver' || v == 'premium') return UserTier.silder;
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
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

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
        return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Upgrade required',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  border: Border.all(
                    color: AppColors.accentPurple.withOpacity(isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentPurple, AppColors.accentPink],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: AppSpacing.spacingMD),
                        Expanded(
                          child: Text(
                            featureTitle,
                            style: AppTypography.h2.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (featureDescription != null) ...[
                      SizedBox(height: AppSpacing.spacingMD),
                      Text(
                        featureDescription!,
                        style: AppTypography.body.copyWith(
                          color: secondaryTextColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                    SizedBox(height: AppSpacing.spacingMD),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingMD,
                        vertical: AppSpacing.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                      child: Text(
                        'Required tier: $tierLabel',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.spacingXL),
              Text(
                'Upgrade to unlock:',
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              _Bullet(text: 'See who liked you'),
              _Bullet(text: 'Advanced filters'),
              _Bullet(text: 'Boosts and superlikes'),
              _Bullet(text: 'More control + better matches'),
              const Spacer(),
              GradientButton(
                text: 'View plans',
                onPressed: () {
                  ref.read(appEventTrackerProvider).track(
                    'paywall_cta',
                    meta: {'cta': 'view_plans', 'feature': featureTitle, 'min_tier': minTier.key},
                  );
                  context.push(AppRoutes.subscriptionPlans);
                },
                isFullWidth: true,
              ),
              SizedBox(height: AppSpacing.spacingMD),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.tierComparison),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentPurple,
                    side: BorderSide(color: AppColors.accentPurple.withOpacity(0.65)),
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingMD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    ),
                  ),
                  child: Text(
                    'Compare tiers',
                    style: AppTypography.button.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.spacingSM),
              TextButton(
                onPressed: () {
                  ref.read(appEventTrackerProvider).track(
                    'paywall_dismiss',
                    meta: {'feature': featureTitle, 'min_tier': minTier.key},
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
      ),
    );
      },
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_rounded, size: 18, color: AppColors.onlineGreen),
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(color: textColor, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

