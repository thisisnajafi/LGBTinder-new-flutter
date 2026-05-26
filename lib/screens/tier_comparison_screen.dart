import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/typography.dart';
import '../routes/app_router.dart';
import '../shared/analytics/app_event_tracker.dart';
import '../widgets/buttons/gradient_button.dart';
import '../core/widgets/app_page_scaffold.dart';
import '../core/widgets/app_page_header.dart';

class TierComparisonScreen extends StatelessWidget {
  const TierComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Consumer(
      builder: (context, ref, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appEventTrackerProvider).track('tier_compare_view', meta: {'screen': 'tier_comparison'});
        });
        return AppPageScaffold(
      title: 'Compare tiers',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.spacingLG),
          children: [
            Text(
              'Choose the tier that fits you',
              style: AppTypography.h1.copyWith(color: textColor, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: AppSpacing.spacingSM),
            Text(
              'Upgrade anytime. Your benefits update instantly.',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
            ),
            SizedBox(height: AppSpacing.spacingXL),
            _TierCard(
              title: 'Basid',
              subtitle: 'Great to start',
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              titleColor: textColor,
              subtitleColor: secondaryTextColor,
              accent: AppColors.accentPurple,
              bullets: const [
                'Discovery + swiping',
                'Basic messaging limits',
                'Standard filters',
              ],
            ),
            SizedBox(height: AppSpacing.spacingLG),
            _TierCard(
              title: 'Silder',
              subtitle: 'Best for faster matches',
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              titleColor: textColor,
              subtitleColor: secondaryTextColor,
              accent: AppColors.accentPink,
              highlight: true,
              bullets: const [
                'See who liked you',
                'Advanced filters',
                'More superlikes/boosts',
                'More messaging freedom',
              ],
            ),
            SizedBox(height: AppSpacing.spacingLG),
            _TierCard(
              title: 'Golden',
              subtitle: 'Everything unlocked',
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              titleColor: textColor,
              subtitleColor: secondaryTextColor,
              accent: AppColors.warningYellow,
              bullets: const [
                'All Silder benefits',
                'Highest limits + priority perks',
                'Exclusive badges/visibility boosts',
              ],
            ),
            SizedBox(height: AppSpacing.spacingXL),
            GradientButton(
              text: 'View plans',
              onPressed: () {
                ref.read(appEventTrackerProvider).track('tier_compare_cta', meta: {'cta': 'view_plans'});
                context.push(AppRoutes.subscriptionPlans);
              },
              isFullWidth: true,
            ),
            SizedBox(height: AppSpacing.spacingMD),
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
  final String title;
  final String subtitle;
  final List<String> bullets;
  final Color surfaceColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color accent;
  final bool highlight;

  const _TierCard({
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.surfaceColor,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.accent,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: highlight ? accent : borderColor, width: highlight ? 2 : 1),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h2.copyWith(color: titleColor, fontWeight: FontWeight.w800),
                ),
              ),
              if (highlight)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingSM,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, AppColors.accentPurple]),
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  ),
                  child: Text(
                    'Recommended',
                    style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingXS),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(color: subtitleColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ...bullets.map(
            (b) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: accent),
                  SizedBox(width: AppSpacing.spacingSM),
                  Expanded(
                    child: Text(
                      b,
                      style: AppTypography.body.copyWith(color: titleColor, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

