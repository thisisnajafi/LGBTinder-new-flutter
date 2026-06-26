import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../routes/app_router.dart';
import '../../../features/payments/data/models/plan_limits.dart';

/// Premium banner when daily swipe quota is running low.
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

    if (remaining > limit * 0.5) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isHealthy = remaining > 3;
    final accent = isHealthy ? AppColors.onlineGreen : AppColors.warningYellow;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumPageHeader.horizontalPadding,
        0,
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingSM,
      ),
      child: PremiumShell(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: isHealthy
                      ? AppIcons.getIconPath('heart')
                      : AppIcons.getIconPath('warning-2'),
                  size: 18,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacingSM),
            Expanded(
              child: Text(
                '$remaining swipes left today ($used/$limit used)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!limits.planInfo.isPremium)
              PremiumTapScale(
                onTap: () => context.push(AppRoutes.subscriptionPlans),
                semanticLabel: 'Upgrade for more swipes',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingMD,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: accent.withValues(alpha: 0.14),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Upgrade',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
