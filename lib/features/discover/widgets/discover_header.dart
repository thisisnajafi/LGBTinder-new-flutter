import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/data/models/passport_location.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../core/widgets/profile_image_widget.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/loading/skeleton_loader.dart';
import '../../payments/data/services/plan_limits_service.dart';
import '../../profile/presentation/widgets/own_profile/profile_photo_utils.dart';
import '../../profile/providers/profile_page_cache_provider.dart';

/// Greeting for the given local time ("Good morning" … "Good night").
String discoverGreetingFor(DateTime now) {
  final hour = now.hour;
  if (hour >= 6 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 18) return 'Good afternoon';
  if (hour >= 18 && hour < 22) return 'Good evening';
  return 'Good night';
}

/// Discover top bar: one compact row with the user's avatar, a two-line
/// greeting and the page actions.
///
/// Replaces the separate "Discover" title bar and greeting card, so the
/// swipe card gets the height of one of them back. The bar is spoken as
/// "Discover" to screen readers.
///
/// Usage:
/// ```dart
/// DiscoverHeader(
///   actions: [
///     DiscoverHeader.action(
///       iconPath: AppIcons.filter,
///       label: 'Open filters',
///       onPressed: _openFilters,
///     ),
///   ],
/// )
/// ```
class DiscoverHeader extends ConsumerWidget {
  const DiscoverHeader({super.key, this.actions = const []});

  /// Trailing controls. Build them with [DiscoverHeader.action].
  final List<Widget> actions;

  /// "View my profile" avatar button (tests).
  @visibleForTesting
  static const Key avatarKey = ValueKey('discover-header-avatar');

  /// A header icon button with a 48 dp tap area.
  static Widget action({
    Key? key,
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
    bool showBadge = false,
  }) {
    return CompactHeaderIconButton(
      key: key,
      iconPath: iconPath,
      semanticLabel: label,
      showBadge: showBadge,
      touchTargetSize: CompactHeaderIconButton.largeTouchSize,
      onPressed: onPressed,
    );
  }

  static String? _displayFirstName(String? raw) {
    final name = raw?.trim();
    if (name == null || name.isEmpty || name == 'User') return null;
    return name;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the three fields painted here: other profile edits (bio, photos
    // order, settings) no longer rebuild the Discover header.
    final (firstName, avatarUrl, isOnline) = ref.watch(
      profilePageCacheProvider.select((state) {
        final profile = state.valueOrNull?.profile;
        return (
          _displayFirstName(profile?.firstName),
          primaryProfileImage(profile?.images)?.imageUrl,
          profile?.isOnline ?? false,
        );
      }),
    );

    return DiscoverHeaderView(
      greeting: discoverGreetingFor(DateTime.now()),
      firstName: firstName,
      avatarUrl: avatarUrl,
      isOnline: isOnline,
      onAvatarTap: () => context.goNamed('profile'),
      actions: actions,
    );
  }
}

/// The painted Discover header, without any provider: [DiscoverHeader] feeds
/// it from the profile cache.
class DiscoverHeaderView extends StatelessWidget {
  const DiscoverHeaderView({
    super.key,
    required this.greeting,
    required this.firstName,
    required this.onAvatarTap,
    this.avatarUrl,
    this.isOnline = false,
    this.actions = const [],
  });

  final String greeting;

  /// Null while the profile is loading: a skeleton bar is shown instead.
  final String? firstName;
  final String? avatarUrl;
  final bool isOnline;
  final VoidCallback onAvatarTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CompactPageHeader(
      title: 'Discover',
      // 4 + the avatar's own 4 dp inset keeps the 40 dp avatar concentric
      // with the rounded end of the bar.
      contentPadding: const EdgeInsetsDirectional.only(
        start: AppSpacing.spacingXS,
        end: AppSpacing.spacingSM,
      ),
      // The 48 dp targets already leave 8 dp between the 40 dp faces.
      actionSpacing: 0,
      leading: _AvatarButton(
        key: DiscoverHeader.avatarKey,
        avatarUrl: avatarUrl,
        isOnline: isOnline,
        onTap: onAvatarTap,
      ),
      titleContent: _GreetingBlock(
        greeting: greeting,
        firstName: firstName,
      ),
      actions: actions,
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    super.key,
    required this.avatarUrl,
    required this.isOnline,
    required this.onTap,
  });

  final String? avatarUrl;
  final bool isOnline;
  final VoidCallback onTap;

  static const double _touchSize = 48;
  static const double _ringSize = 40;
  static const double _photoSize = 34;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'View my profile',
      excludeSemantics: true,
      child: SizedBox(
        width: _touchSize,
        height: _touchSize,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            AppHaptics.light();
            onTap();
          },
          child: Center(
            child: SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: _ringSize,
                    height: _ringSize,
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
                          width: _photoSize,
                          height: _photoSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  if (isOnline)
                    PositionedDirectional(
                      end: 0,
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
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.greeting, required this.firstName});

  final String greeting;
  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          greeting,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: secondary,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        if (firstName == null)
          const SkeletonLoader(
            width: 96,
            height: 14,
            borderRadius: BorderRadius.all(
              Radius.circular(AppRadius.radiusSM),
            ),
          )
        else
          AppText(
            firstName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
      ],
    );
  }
}

/// Today's swipe allowance, as shown in the Discover quota chip.
@immutable
class DiscoverSwipeQuota {
  const DiscoverSwipeQuota({
    required this.remaining,
    required this.limit,
    required this.used,
  });

  final int remaining;
  final int limit;
  final int used;

  /// Share of today's swipes already used, 0..1.
  double get progress => limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is DiscoverSwipeQuota &&
      other.remaining == remaining &&
      other.limit == limit &&
      other.used == used;

  @override
  int get hashCode => Object.hash(remaining, limit, used);
}

/// Slim chip row under [DiscoverHeader]: active Passport location, today's
/// swipe quota and the Upgrade shortcut.
///
/// Takes only a small gap when there is nothing to show (unlimited plan, no
/// Passport). The row scrolls sideways instead of wrapping, so it is always
/// one line.
class DiscoverStatusChips extends ConsumerWidget {
  const DiscoverStatusChips({
    super.key,
    required this.passport,
    required this.onReturnHome,
    this.isClearingPassport = false,
  });

  final PassportLocation passport;
  final VoidCallback onReturnHome;
  final bool isClearingPassport;

  /// Row height. Chips are 32 dp tall; the rest is tap area and breathing
  /// room above the card.
  static const double height = 48;

  @visibleForTesting
  static const Key passportChipKey = ValueKey('discover-chip-passport');
  @visibleForTesting
  static const Key quotaChipKey = ValueKey('discover-chip-quota');
  @visibleForTesting
  static const Key upgradeChipKey = ValueKey('discover-chip-upgrade');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild only when a number shown here changes, not on every plan
    // limits refresh.
    final (quota, showUpgrade) = ref.watch(
      planLimitsProvider.select((state) {
        final limits = state.valueOrNull;
        if (limits == null) return (null, false);
        final swipes = limits.usage.swipes;
        return (
          swipes.isUnlimited
              ? null
              : DiscoverSwipeQuota(
                  remaining: swipes.remaining,
                  limit: swipes.limit,
                  used: swipes.usedToday,
                ),
          !limits.planInfo.isPremium,
        );
      }),
    );

    return DiscoverStatusChipsView(
      passportLabel: passport.active ? passport.displayLabel : null,
      isClearingPassport: isClearingPassport,
      onReturnHome: onReturnHome,
      quota: quota,
      onUpgrade: showUpgrade
          ? () => context.push(AppRoutes.subscriptionPlans)
          : null,
    );
  }
}

/// The painted chip row, without any provider: [DiscoverStatusChips] feeds
/// it from the plan limits.
class DiscoverStatusChipsView extends StatelessWidget {
  const DiscoverStatusChipsView({
    super.key,
    required this.onReturnHome,
    this.passportLabel,
    this.isClearingPassport = false,
    this.quota,
    this.onUpgrade,
  });

  /// Passport location being explored. Null hides the chip.
  final String? passportLabel;
  final bool isClearingPassport;
  final VoidCallback onReturnHome;

  /// Null hides the quota chip (unlimited plan, or limits not loaded).
  final DiscoverSwipeQuota? quota;

  /// Null hides the Upgrade chip (already on a paid plan).
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final label = passportLabel;
    final swipes = quota;
    final upgrade = onUpgrade;
    if (label == null && swipes == null && upgrade == null) {
      return const SizedBox(height: AppSpacing.spacingSM);
    }

    final chips = <Widget>[
      if (label != null)
        _PassportChip(
          key: DiscoverStatusChips.passportChipKey,
          label: label,
          isClearing: isClearingPassport,
          onTap: onReturnHome,
        ),
      if (swipes != null)
        _QuotaChip(key: DiscoverStatusChips.quotaChipKey, quota: swipes),
      if (upgrade != null)
        _UpgradeChip(key: DiscoverStatusChips.upgradeChipKey, onTap: upgrade),
    ];

    return SizedBox(
      height: DiscoverStatusChips.height,
      child: ClampedTextScale(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: CompactPageHeader.horizontalMargin,
          ),
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.spacingSM),
                chips[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared pill look of the Discover status chips.
class _ChipShell extends StatelessWidget {
  const _ChipShell({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  static const double visualHeight = 32;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minHeight: visualHeight),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.spacingMD,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark.withValues(alpha: 0.92)
            : AppColors.cardBackgroundLight.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: borderColor ??
              AppColors.accentViolet.withValues(alpha: isDark ? 0.22 : 0.16),
        ),
      ),
      child: child,
    );
  }
}

class _QuotaChip extends StatelessWidget {
  const _QuotaChip({super.key, required this.quota});

  final DiscoverSwipeQuota quota;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = quota.remaining;
    final limit = quota.limit;
    final accent = remaining <= 0
        ? AppColors.accentRose
        : remaining <= 3
            ? AppColors.warningYellow
            : AppColors.onlineGreen;
    return Semantics(
      label: limit > 0
          ? '$remaining of $limit swipes left today'
          : '$remaining swipes left today',
      excludeSemantics: true,
      child: Center(
        child: _ChipShell(
          borderColor: accent.withValues(alpha: 0.4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                assetPath: remaining <= 3
                    ? AppIcons.getIconPath('warning-2')
                    : AppIcons.heart,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.spacingXS + 2),
              // Text stays in the normal text colour: the status colours
              // (yellow, green) do not reach AA contrast on a light chip.
              AppText(
                remaining == 1 ? '1 swipe left' : '$remaining swipes left',
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                child: SizedBox(
                  width: 32,
                  child: LinearProgressIndicator(
                    value: quota.progress,
                    minHeight: 4,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeChip extends StatelessWidget {
  const _UpgradeChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumTapScale(
      semanticLabel: 'Upgrade for more swipes',
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      // Full row height is the tap area; only the pill is painted.
      child: ExcludeSemantics(
        child: SizedBox(
        height: DiscoverStatusChips.height,
        child: Center(
          child: _ChipShell(
            borderColor: AppColors.accentViolet.withValues(alpha: 0.45),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.crown,
                  size: 14,
                  color: AppColors.accentViolet,
                ),
                const SizedBox(width: AppSpacing.spacingXS + 2),
                AppText(
                  'Upgrade',
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
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

class _PassportChip extends StatelessWidget {
  const _PassportChip({
    super.key,
    required this.label,
    required this.isClearing,
    required this.onTap,
  });

  final String label;
  final bool isClearing;
  final VoidCallback onTap;

  static const double _maxLabelWidth = 160;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return PremiumTapScale(
      semanticLabel: 'Return from passport location',
      onTap: isClearing
          ? () {}
          : () {
              AppHaptics.light();
              onTap();
            },
      // The label above is the whole announcement; the visible words would
      // only repeat it.
      child: ExcludeSemantics(
        child: SizedBox(
        height: DiscoverStatusChips.height,
        child: Center(
            child: _ChipShell(
              borderColor: AppColors.accentRose.withValues(alpha: 0.45),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.map,
                    size: 14,
                    color: AppColors.accentViolet,
                  ),
                  const SizedBox(width: AppSpacing.spacingXS + 2),
                  // Long place names are cut; "Return home" never is. The
                  // row scrolls, so the chip itself needs no width cap.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxLabelWidth),
                    child: AppText(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppText(
                    ' · Return home',
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacingXS + 2),
                  if (isClearing)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: AppSvgIcon(
                        assetPath: AppIcons.getIconPath('arrow-right-3'),
                        size: 12,
                        color: muted,
                      ),
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
