import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../routes/app_router.dart';
import '../../../features/payments/data/models/plan_limits.dart';
import '../../../core/responsive/responsive.dart';

/// Premium banner when the daily swipe quota is limited.
class DiscoverSwipeLimitBanner extends StatelessWidget {
  const DiscoverSwipeLimitBanner({
    super.key,
    required this.limits,
  });

  final PlanLimits limits;

  @override
  Widget build(BuildContext context) {
    if (limits.usage.swipes.isUnlimited) {
      return const SizedBox.shrink();
    }

    final remaining = limits.usage.swipes.remaining;
    final used = limits.usage.swipes.usedToday;
    final limit = limits.usage.swipes.limit;
    final progress = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);

    final theme = Theme.of(context);
    final accent = remaining <= 0
        ? AppColors.accentRose
        : remaining <= 3
            ? AppColors.warningYellow
            : AppColors.onlineGreen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumPageHeader.horizontalPadding,
        0,
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingSM,
      ),
      child: PremiumTapScale(
        onTap: () => context.push(AppRoutes.subscriptionPlans),
        semanticLabel: 'Upgrade for more swipes',
        child: PremiumShell(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 320;
                  final message = Expanded(
                    child: AppText(
                      '$remaining swipes left today ($used/$limit used)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                    ),
                  );
                  final upgradeChip = !limits.planInfo.isPremium
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingMD,
                            vertical: AppSpacing.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppRadius.radiusRound,
                            ),
                            color: accent.withValues(alpha: 0.14),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: AppText(
                            'Upgrade',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                          ),
                        )
                      : null;

                  final icon = Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.14),
                    ),
                    child: Center(
                      child: AppSvgIcon(
                        assetPath: remaining <= 3
                            ? AppIcons.getIconPath('warning-2')
                            : AppIcons.heart,
                        size: 18,
                        color: accent,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            icon,
                            const SizedBox(width: AppSpacing.spacingSM),
                            message,
                          ],
                        ),
                        if (upgradeChip != null) ...[
                          const SizedBox(height: AppSpacing.spacingSM),
                          Align(
                            alignment: Alignment.centerRight,
                            child: upgradeChip,
                          ),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      icon,
                      const SizedBox(width: AppSpacing.spacingSM),
                      message,
                      if (upgradeChip != null) upgradeChip,
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.spacingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: AppSpacing.spacingXS,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
