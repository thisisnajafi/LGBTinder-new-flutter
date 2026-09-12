import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/location/data/models/passport_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../core/responsive/responsive.dart';

/// Shown on discover when a premium passport search location is active.
class DiscoverPassportBanner extends StatelessWidget {
  const DiscoverPassportBanner({
    super.key,
    required this.passport,
    required this.onReturnHome,
    this.isClearing = false,
  });

  final PassportLocation passport;
  final VoidCallback onReturnHome;
  final bool isClearing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration =
        disableAnimations ? Duration.zero : AppAnimations.transitionModal;
    final label = passport.displayLabel;

    return AnimatedSize(
      duration: duration,
      curve: AppAnimations.curveDefault,
      alignment: Alignment.topCenter,
      child: !passport.active
          ? const SizedBox(width: double.infinity)
          : TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: -AppSpacing.spacingLG, end: 0),
              duration: duration,
              curve: AppAnimations.curveDefault,
              builder: (context, dy, child) {
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PremiumPageHeader.horizontalPadding,
                  0,
                  PremiumPageHeader.horizontalPadding,
                  AppSpacing.spacingSM,
                ),
                child: PremiumTapScale(
                  onTap: isClearing ? () {} : onReturnHome,
                  semanticLabel: 'Return from passport location',
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
                            color: theme.colorScheme.surface,
                            border: Border.all(
                              color: AppColors.accentViolet.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Center(
                            child: AppSvgIcon(
                              assetPath: AppIcons.map,
                              size: 18,
                              color: AppColors.accentViolet,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacingSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'Passport active',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.accentRose,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: AppSpacing.spacingXS),
                              AppText(
                                'Exploring $label · Return home',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        if (isClearing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          AppSvgIcon(
                            assetPath: AppIcons.getIconPath('arrow-right-3'),
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
