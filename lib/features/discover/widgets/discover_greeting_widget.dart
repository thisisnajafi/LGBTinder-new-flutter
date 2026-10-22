import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/profile_image_widget.dart';
import '../../../features/payments/data/services/plan_limits_service.dart';
import '../../../routes/app_router.dart';
import '../../../features/profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../../../features/profile/providers/profile_page_cache_provider.dart';
import '../../../widgets/loading/skeleton_loader.dart';

/// Compact Discover greeting card: avatar, "Good morning, {name}", the daily
/// swipe quota (with a thin progress bar) and the Upgrade button, all in one
/// row so the swipe card gets the remaining height.
class DiscoverGreetingWidget extends ConsumerWidget {
  const DiscoverGreetingWidget({super.key});

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    if (hour >= 18 && hour < 22) return 'Good evening';
    return 'Good night';
  }

  String? _displayFirstName(String? raw) {
    final name = raw?.trim();
    if (name == null || name.isEmpty || name == 'User') return null;
    return name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileState = ref.watch(profilePageCacheProvider);
    final greeting = _timeBasedGreeting();
    final profile = profileState.valueOrNull?.profile;
    final firstName = _displayFirstName(profile?.firstName);
    final avatarUrl = primaryProfileImage(profile?.images)?.imageUrl;
    final isOnline = profile?.isOnline ?? false;
    final limits = ref.watch(planLimitsProvider).valueOrNull;
    final swipes = limits?.usage.swipes;
    final showQuota = swipes != null && !swipes.isUnlimited;
    final remaining = swipes?.remaining ?? 0;
    final limit = swipes?.limit ?? 0;
    final used = swipes?.usedToday ?? 0;
    final progress = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final accent = remaining <= 0
        ? AppColors.accentRose
        : remaining <= 3
            ? AppColors.warningYellow
            : AppColors.onlineGreen;
    final showUpgrade = limits != null && !limits.planInfo.isPremium;

    return Padding(
      padding: ResponsivePadding.horizontal(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingXS),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingXS + 2,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark.withValues(alpha: 0.92)
              : AppColors.cardBackgroundLight.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.radiusXL),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'View my profile',
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      AppHaptics.light();
                      context.goNamed('profile');
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.brandGradient,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                            ),
                            child: ClipOval(
                              child: ProfileImageWidget(
                                imageUrl: avatarUrl,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.onlineGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacingSM + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (firstName == null)
                    const SkeletonLoader(
                      height: 14,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.radiusSM),
                      ),
                    )
                  else
                    AppText(
                      '$greeting, $firstName',
                      maxLines: 1,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (showQuota) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AppSvgIcon(
                          assetPath: remaining <= 3
                              ? AppIcons.getIconPath('warning-2')
                              : AppIcons.heart,
                          size: 12,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: AppText(
                            '$remaining swipes left today',
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusRound),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: 0.16),
                      ),
                    ),
                  ] else
                    AppText(
                      'Swipe and connect',
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
            if (showUpgrade) ...[
              const SizedBox(width: AppSpacing.spacingSM),
              Semantics(
                button: true,
                label: 'Upgrade for more swipes',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                  onTap: () {
                    AppHaptics.light();
                    context.push(AppRoutes.subscriptionPlans);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingSM + 2,
                      vertical: AppSpacing.spacingXS + 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusRound),
                      color: accent.withValues(alpha: 0.14),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: AppText(
                      'Upgrade',
                      maxLines: 1,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
