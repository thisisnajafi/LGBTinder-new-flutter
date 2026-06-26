import 'package:flutter/material.dart';

import '../../../core/location/data/models/passport_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';

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
    if (!passport.active) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final label = passport.displayLabel;

    return Padding(
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
                  gradient: AppColors.brandGradient,
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.map,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passport active',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.accentRose,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Exploring $label',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    );
  }
}
