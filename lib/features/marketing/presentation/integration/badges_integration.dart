import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../providers/marketing_providers.dart';
import '../../data/models/badge_model.dart';
import '../widgets/badge_display.dart';

/// Badges link for settings screen
/// Part of the Marketing System Implementation (Task 3.6.3)
/// 
/// Usage:
/// ```dart
/// BadgesSettingsTile()
/// BadgesSettingsTile.compact()
/// ```
class BadgesSettingsTile extends ConsumerWidget {
  final bool compact;
  final VoidCallback? onTap;

  const BadgesSettingsTile({
    Key? key,
    this.compact = false,
    this.onTap,
  }) : super(key: key);

  factory BadgesSettingsTile.compact({VoidCallback? onTap}) {
    return BadgesSettingsTile(compact: true, onTap: onTap);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final badgesAsync = ref.watch(myBadgesProvider);
    final eligibilityAsync = ref.watch(badgeEligibilityProvider);

    final earnedCount = badgesAsync.maybeWhen(
      data: (badges) => badges.length,
      orElse: () => 0,
    );

    final eligibleCount = eligibilityAsync.maybeWhen(
      data: (e) => e.eligibleBadges.length,
      orElse: () => 0,
    );

    if (compact) {
      return ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events, color: AppColors.accentPurple),
            ),
            if (eligibleCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.notificationRed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$eligibleCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text('Badges & Achievements', style: TextStyle(color: textColor)),
        subtitle: Text(
          earnedCount > 0 ? '$earnedCount earned' : 'Earn badges for activities',
          style: TextStyle(color: secondaryTextColor),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _handleTap(context),
      );
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        ),
        child: Row(
          children: [
            // Icon with notification
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentPurple, AppColors.accentGradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(Icons.emoji_events, color: Colors.white),
                  ),
                  if (eligibleCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.notificationRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '$eligibleCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.spacingMD),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Badges & Achievements',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (eligibleCount > 0)
                    Text(
                      '$eligibleCount new badges available!',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.onlineGreen,
                      ),
                    )
                  else if (earnedCount > 0)
                    Text(
                      '$earnedCount badges earned',
                      style: AppTypography.caption,
                    )
                  else
                    Text(
                      'Complete activities to earn badges',
                      style: AppTypography.caption,
                    ),
                ],
              ),
            ),
            // Preview badges
            badgesAsync.maybeWhen(
              data: (badges) {
                if (badges.isEmpty) return const SizedBox.shrink();
                return BadgeRow(
                  badges: badges.take(3).toList(),
                  maxDisplay: 3,
                  badgeSize: 28,
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            SizedBox(width: AppSpacing.spacingSM),
            Icon(Icons.chevron_right, color: secondaryTextColor),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      context.push('/badges');
    }
  }
}

/// Profile badges display widget
/// Shows earned badges on user profile
class ProfileBadgesDisplay extends ConsumerWidget {
  final int? userId;
  final int maxDisplay;
  final VoidCallback? onViewAll;

  const ProfileBadgesDisplay({
    Key? key,
    this.userId,
    this.maxDisplay = 5,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    // Use displayedBadges for own profile, userBadges for others
    final badgesAsync = userId != null
        ? ref.watch(userBadgesProvider(userId!))
        : ref.watch(displayedBadgesProvider);

    return badgesAsync.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Badges',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.spacingSM),
            BadgeRow(
              badges: badges,
              maxDisplay: maxDisplay,
              badgeSize: 40,
              onViewAll: onViewAll,
            ),
          ],
        );
      },
    );
  }
}

/// Mini badge preview for match cards, chat lists, etc.
class MiniBadgePreview extends ConsumerWidget {
  final int userId;
  final int maxDisplay;

  const MiniBadgePreview({
    Key? key,
    required this.userId,
    this.maxDisplay = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider(userId));

    return badgesAsync.maybeWhen(
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();
        return BadgeRow(
          badges: badges,
          maxDisplay: maxDisplay,
          badgeSize: 20,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
