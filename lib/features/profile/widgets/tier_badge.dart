import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../features/payments/presentation/utils/plan_theme_helper.dart';
import '../../../shared/models/user_tier.dart';

/// Tier badge for basid / silder / golden users.
class TierBadge extends ConsumerWidget {
  final UserTier tier;
  final bool compact;

  const TierBadge({
    super.key,
    required this.tier,
    this.compact = false,
  });

  factory TierBadge.fromPremium(bool isPremium) {
    return TierBadge(
      tier: isPremium ? UserTier.silder : UserTier.basid,
    );
  }

  String get _label => switch (tier) {
        UserTier.basid => 'Basid',
        UserTier.silder => 'Silder',
        UserTier.golden => 'Golden',
      };

  LinearGradient get _gradient {
    if (tier == UserTier.golden) {
      return getPlanTheme('Golden').gradient ?? AppColors.brandGradient;
    }
    if (tier == UserTier.silder) {
      return getPlanTheme('Premium').gradient ?? AppColors.brandGradient;
    }
    return getPlanTheme('Basic').gradient ?? AppColors.brandGradient;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final iconPath = tier == UserTier.golden
        ? AppIcons.getIconPath('crown', style: 'bold')
        : AppIcons.getIconPath('star', style: 'bold');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.spacingSM : AppSpacing.spacingMD,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        boxShadow: tier == UserTier.golden
            ? [
                BoxShadow(
                  color: AppColors.warningYellow.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: iconPath,
            size: compact ? 14 : 16,
            color: AppColors.textPrimaryDark,
          ),
          if (!compact) ...[
            SizedBox(width: AppSpacing.spacingXS),
            Text(
              _label,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header row for photo overlay: name, age, badges.
class ProfileOverlayHeader extends ConsumerWidget {
  final String name;
  final int? age;
  final bool isVerified;
  final UserTier? tier;
  final bool isPremiumFallback;
  final String? location;
  final String? distance;

  const ProfileOverlayHeader({
    super.key,
    required this.name,
    this.age,
    this.isVerified = false,
    this.tier,
    this.isPremiumFallback = false,
    this.location,
    this.distance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final resolvedTier = tier ?? (isPremiumFallback ? UserTier.silder : UserTier.basid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                age != null ? '$name, $age' : name,
                style: textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isVerified) ...[
              SizedBox(width: AppSpacing.spacingSM),
              AppSvgIcon(
                assetPath: AppIcons.getIconPath('verify', style: 'bold'),
                size: 22,
                color: AppColors.accentPurple,
              ),
            ],
          ],
        ),
        SizedBox(height: AppSpacing.spacingSM),
        Row(
          children: [
            TierBadge(tier: resolvedTier, compact: false),
            if (location != null || distance != null) ...[
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Row(
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.location,
                      size: 16,
                      color: AppColors.textPrimaryDark.withValues(alpha: 0.85),
                    ),
                    SizedBox(width: AppSpacing.spacingXS),
                    Expanded(
                      child: Text(
                        [
                          if (distance != null) distance,
                          if (location != null) location,
                        ].whereType<String>().join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimaryDark.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
