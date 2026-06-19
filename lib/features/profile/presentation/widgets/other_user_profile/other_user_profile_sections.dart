import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/animation_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/border_radius_constants.dart';
import '../../../../../core/theme/spacing_constants.dart';
import '../../../../../core/utils/app_icons.dart';
import '../../../../../core/widgets/profile_age_badge.dart';
import '../../../../../core/widgets/profile_image_widget.dart';
import '../../../../../shared/models/user_tier.dart';
import '../../../widgets/tier_badge.dart';
import '../../../data/models/user_profile.dart';
import '../own_profile/profile_details_sections.dart';
import '../own_profile/profile_premium_shell.dart';

/// Compatibility snapshot for another user's profile.
class ProfileCompatibilityData {
  const ProfileCompatibilityData({
    required this.matchPercent,
    required this.sharedInterests,
    required this.sharedValues,
    required this.sharedLifestyle,
  });

  final int matchPercent;
  final List<String> sharedInterests;
  final List<String> sharedValues;
  final List<String> sharedLifestyle;
}

ProfileCompatibilityData computeProfileCompatibility({
  required List<String> theirInterests,
  required List<String> viewerInterests,
  required List<String> theirGoals,
  required List<String> viewerGoals,
  required bool? theirSmoke,
  required bool? viewerSmoke,
  required bool? theirDrink,
  required bool? viewerDrink,
  required bool? theirGym,
  required bool? viewerGym,
  int? apiMatchPercent,
}) {
  final sharedInterests = theirInterests
      .where((i) => viewerInterests.contains(i))
      .toSet()
      .toList();

  final sharedValues = theirGoals
      .where((g) => viewerGoals.contains(g))
      .toSet()
      .toList();

  final sharedLifestyle = <String>[];
  if (theirSmoke != null && viewerSmoke != null && theirSmoke == viewerSmoke) {
    sharedLifestyle.add(theirSmoke ? 'Both smoke' : 'Non-smokers');
  }
  if (theirDrink != null && viewerDrink != null && theirDrink == viewerDrink) {
    sharedLifestyle.add(theirDrink ? 'Both drink' : 'Rarely drink');
  }
  if (theirGym != null && viewerGym != null && theirGym == viewerGym) {
    sharedLifestyle.add(theirGym ? 'Both active' : 'Relaxed lifestyle');
  }

  if (apiMatchPercent != null && apiMatchPercent > 0) {
    return ProfileCompatibilityData(
      matchPercent: apiMatchPercent.clamp(0, 100),
      sharedInterests: sharedInterests,
      sharedValues: sharedValues,
      sharedLifestyle: sharedLifestyle,
    );
  }

  var score = 62;
  score += (sharedInterests.length * 6).clamp(0, 24);
  score += (sharedValues.length * 8).clamp(0, 16);
  score += (sharedLifestyle.length * 4).clamp(0, 12);
  if (theirInterests.isNotEmpty && sharedInterests.isEmpty) {
    score -= 4;
  }

  return ProfileCompatibilityData(
    matchPercent: score.clamp(48, 98),
    sharedInterests: sharedInterests,
    sharedValues: sharedValues,
    sharedLifestyle: sharedLifestyle,
  );
}

/// Compact photo hero (~35% viewport) with integrated identity.
class OtherUserProfileHero extends StatelessWidget {
  const OtherUserProfileHero({
    super.key,
    required this.imageUrls,
    required this.photoIndex,
    required this.fullName,
    required this.age,
    required this.isVerified,
    required this.isOnline,
    required this.tier,
    required this.locationLabel,
    required this.matchPercent,
    required this.sharedInterestCount,
    required this.recentlyActiveLabel,
    required this.onBack,
    required this.onPhotoTap,
  });

  final List<String> imageUrls;
  final int photoIndex;
  final String fullName;
  final int? age;
  final bool isVerified;
  final bool isOnline;
  final UserTier tier;
  final String locationLabel;
  final int? matchPercent;
  final int sharedInterestCount;
  final String? recentlyActiveLabel;
  final VoidCallback onBack;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenH * 0.36).clamp(260.0, 340.0);
    final topInset = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroPhoto(
            urls: imageUrls,
            index: photoIndex,
            onTap: onPhotoTap,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.42),
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          if (imageUrls.length > 1)
            Positioned(
              top: topInset + AppSpacing.spacingSM,
              left: AppSpacing.spacingLG + 48,
              right: AppSpacing.spacingLG,
              child: _PhotoSegments(count: imageUrls.length, active: photoIndex),
            ),
          Positioned(
            top: topInset + AppSpacing.spacingXS,
            left: AppSpacing.spacingSM,
            child: _HeroIconButton(
              icon: AppIcons.arrowLeft,
              onTap: onBack,
              tooltip: 'Back',
              light: true,
            ),
          ),
          Positioned(
            left: AppSpacing.spacingLG,
            right: AppSpacing.spacingLG,
            bottom: AppSpacing.spacingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.spacingSM,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (age != null)
                            ProfileAgeBadge(
                              age: age!,
                              style: ProfileAgeBadgeStyle.heroOverlay,
                            ),
                        ],
                      ),
                    ),
                    if (isVerified)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          shape: BoxShape.circle,
                        ),
                        child: AppSvgIcon(
                          assetPath: AppIcons.getIconPath('tick-circle', style: 'bold'),
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Wrap(
                  spacing: AppSpacing.spacingSM,
                  runSpacing: 6,
                  children: [
                    if (tier != UserTier.basid) TierBadge(tier: tier, compact: true),
                    _HeroMetaPill(
                      icon: AppIcons.getIconPath('record-circle'),
                      label: isOnline ? 'Online now' : 'Offline',
                      color: isOnline ? AppColors.onlineGreen : Colors.white70,
                    ),
                    if (locationLabel.isNotEmpty)
                      _HeroMetaPill(
                        icon: AppIcons.location,
                        label: locationLabel,
                        color: Colors.white,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Row(
                  children: [
                    if (matchPercent != null) ...[
                      _HeroStatChip(
                        icon: AppIcons.heart,
                        label: '$matchPercent% match',
                      ),
                      const SizedBox(width: AppSpacing.spacingSM),
                    ],
                    if (sharedInterestCount > 0)
                      _HeroStatChip(
                        icon: AppIcons.getIconPath('heart-tick'),
                        label:
                            '$sharedInterestCount shared interest${sharedInterestCount == 1 ? '' : 's'}',
                      ),
                    if (recentlyActiveLabel != null) ...[
                      const SizedBox(width: AppSpacing.spacingSM),
                      _HeroStatChip(
                        icon: AppIcons.clock,
                        label: recentlyActiveLabel!,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({
    required this.urls,
    required this.index,
    this.onTap,
  });

  final List<String> urls;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (urls.isEmpty) {
      return ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: AppSvgIcon(
            assetPath: AppIcons.userOutline,
            size: 56,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: CachedNetworkImage(
          key: ValueKey<String>(urls[index]),
          imageUrl: urls[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _PhotoSegments extends StatelessWidget {
  const _PhotoSegments({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 3,
            margin: EdgeInsets.only(right: i < count - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: i == active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(assetPath: icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentPink.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.accentPink.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(assetPath: icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Integrated profile action bar — pinned below hero.
class OtherUserProfileActionBar extends StatelessWidget {
  const OtherUserProfileActionBar({
    super.key,
    required this.showDiscoveryActions,
    required this.isMatched,
    this.onMessage,
    this.onLike,
    this.onSuperlike,
    this.onShare,
    this.onMore,
  });

  final bool showDiscoveryActions;
  final bool isMatched;
  final VoidCallback? onMessage;
  final VoidCallback? onLike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.08),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacingLG,
        AppSpacing.spacingSM,
        AppSpacing.spacingLG,
        AppSpacing.spacingMD,
      ),
      child: Row(
        children: [
          if (onMessage != null)
            Expanded(
              flex: 3,
              child: _ProfileTapScale(
                onTap: onMessage!,
                semanticLabel: isMatched ? 'Send message' : 'Message',
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.message,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isMatched ? 'Message' : 'Say hi',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showDiscoveryActions) ...[
            const SizedBox(width: AppSpacing.spacingSM),
            if (onLike != null)
              _ProfileTapScale(
                onTap: onLike!,
                semanticLabel: 'Like profile',
                child: _ActionIconButton(
                  icon: AppIcons.heartOutline,
                  color: AppColors.feedbackError,
                ),
              ),
            if (onSuperlike != null) ...[
              const SizedBox(width: AppSpacing.spacingSM),
              _ProfileTapScale(
                onTap: onSuperlike!,
                semanticLabel: 'Superlike profile',
                child: _ActionIconButton(
                  icon: AppIcons.getIconPath('star', style: 'bold'),
                  color: AppColors.warningYellow,
                ),
              ),
            ],
          ],
          if (onShare != null) ...[
            const SizedBox(width: AppSpacing.spacingSM),
            _ProfileTapScale(
              onTap: onShare!,
              semanticLabel: 'Share profile',
              child: _ActionIconButton(
                icon: AppIcons.share,
                color: AppColors.accentViolet,
              ),
            ),
          ],
          if (onMore != null) ...[
            const SizedBox(width: AppSpacing.spacingSM),
            _ProfileTapScale(
              onTap: onMore!,
              semanticLabel: 'More options',
              child: _ActionIconButton(
                icon: AppIcons.more,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({required this.icon, required this.color});

  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Center(
        child: AppSvgIcon(assetPath: icon, size: 20, color: color),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.light = false,
  });

  final String icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light
          ? Colors.black.withValues(alpha: 0.35)
          : Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: AppSvgIcon(
          assetPath: icon,
          size: 22,
          color: light ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Prominent compatibility overview card.
class PremiumCompatibilitySection extends StatelessWidget {
  const PremiumCompatibilitySection({
    super.key,
    required this.data,
    this.shellMargin,
  });

  final ProfileCompatibilityData data;
  final EdgeInsets? shellMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(
            title: 'Compatibility',
            subtitle: 'How well you might connect',
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacingLG),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusLG),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.accentViolet.withValues(alpha: 0.28),
                        AppColors.accentPink.withValues(alpha: 0.18),
                      ]
                    : [
                        AppColors.tintVioletLight,
                        AppColors.tintRoseLight,
                      ],
              ),
              border: Border.all(
                color: AppColors.accentPink.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: _MatchRingPainter(
                      progress: data.matchPercent / 100,
                    ),
                    child: Center(
                      child: Text(
                        '${data.matchPercent}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentPink,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Strong match potential',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on interests, goals, and lifestyle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          _CompatRow(
            icon: AppIcons.heart,
            title: 'Shared interests',
            values: data.sharedInterests,
            empty: 'Explore their interests below',
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          _CompatRow(
            icon: AppIcons.heartTick,
            title: 'Shared values',
            values: data.sharedValues,
            empty: 'Relationship goals may align',
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          _CompatRow(
            icon: AppIcons.getIconPath('weight'),
            title: 'Lifestyle',
            values: data.sharedLifestyle,
            empty: 'Compare lifestyle details below',
          ),
        ],
      ),
    );
  }
}

class _CompatRow extends StatelessWidget {
  const _CompatRow({
    required this.icon,
    required this.title,
    required this.values,
    required this.empty,
  });

  final String icon;
  final String title;
  final List<String> values;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(assetPath: icon, size: 18, color: AppColors.accentViolet),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  values.isEmpty ? empty : values.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRingPainter extends CustomPainter {
  _MatchRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const start = -3.1415926535 / 2;
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);

    final track = Paint()
      ..color = AppColors.accentViolet.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, 3.1415926535 * 2, false, track);

    final arc = Paint()
      ..shader = AppColors.brandGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      start,
      3.1415926535 * 2 * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _MatchRingPainter old) =>
      old.progress != progress;
}

/// Interests with shared-interest highlighting for viewer context.
class PremiumSharedInterestsSection extends StatelessWidget {
  const PremiumSharedInterestsSection({
    super.key,
    required this.allLabels,
    required this.sharedLabels,
    this.shellMargin,
  });

  final List<String> allLabels;
  final Set<String> sharedLabels;
  final EdgeInsets? shellMargin;

  @override
  Widget build(BuildContext context) {
    if (allLabels.isEmpty) return const SizedBox.shrink();

    final unique = allLabels.toSet().toList();
    final shared = unique.where(sharedLabels.contains).toList();
    final other = unique.where((l) => !sharedLabels.contains(l)).toList();

    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(
            title: 'Interests',
            subtitle: shared.isEmpty
                ? '${unique.length} passion${unique.length == 1 ? '' : 's'}'
                : '${shared.length} shared · ${unique.length} total',
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          if (shared.isNotEmpty) ...[
            _InterestGroupTitle(title: 'You both like'),
            const SizedBox(height: AppSpacing.spacingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: shared
                  .map((l) => _InterestPill(label: l, shared: true))
                  .toList(),
            ),
            if (other.isNotEmpty) const SizedBox(height: AppSpacing.spacingMD),
          ],
          if (other.isNotEmpty) ...[
            _InterestGroupTitle(
              title: shared.isEmpty ? 'Their vibe' : 'More interests',
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: other
                  .map((l) => _InterestPill(label: l, shared: false))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterestGroupTitle extends StatelessWidget {
  const _InterestGroupTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.accentViolet,
          ),
    );
  }
}

class _InterestPill extends StatelessWidget {
  const _InterestPill({required this.label, required this.shared});

  final String label;
  final bool shared;

  @override
  Widget build(BuildContext context) {
    final accent = shared ? AppColors.accentPink : AppColors.accentViolet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        gradient: shared ? AppColors.brandGradient : null,
        color: shared
            ? null
            : accent.withValues(alpha: 0.08),
        border: Border.all(
          color: accent.withValues(alpha: shared ? 0.45 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shared) ...[
            AppSvgIcon(
              assetPath: AppIcons.getIconPath('heart-tick'),
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: shared ? Colors.white : accent,
                ),
          ),
        ],
      ),
    );
  }
}

/// Categorized detail groups instead of one flat grid.
class PremiumCategorizedDetailsSection extends StatelessWidget {
  const PremiumCategorizedDetailsSection({
    super.key,
    required this.groups,
    this.shellMargin,
  });

  final List<ProfileDetailGroup> groups;
  final EdgeInsets? shellMargin;

  @override
  Widget build(BuildContext context) {
    if (groups.every((g) => g.chips.isEmpty)) {
      return const SizedBox.shrink();
    }

    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PremiumSectionHeader(
            title: 'Personal details',
            subtitle: 'Identity, lifestyle, and preferences',
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          for (var i = 0; i < groups.length; i++) ...[
            if (groups[i].chips.isNotEmpty) ...[
              if (i > 0) const SizedBox(height: AppSpacing.spacingMD),
              _DetailGroupCard(group: groups[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class ProfileDetailGroup {
  const ProfileDetailGroup({
    required this.title,
    required this.iconPath,
    required this.chips,
  });

  final String title;
  final String iconPath;
  final List<ProfileDetailChipData> chips;
}

class _DetailGroupCard extends StatelessWidget {
  const _DetailGroupCard({required this.group});

  final ProfileDetailGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSvgIcon(
                assetPath: group.iconPath,
                size: 18,
                color: AppColors.accentViolet,
              ),
              const SizedBox(width: 8),
              Text(
                group.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          ...group.chips.map(
            (chip) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chip.accent.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: AppSvgIcon(
                        assetPath: chip.iconPath,
                        size: 16,
                        color: chip.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chip.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          chip.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

/// Read-only photo gallery for another user's profile.
class PremiumViewerPhotosSection extends StatelessWidget {
  const PremiumViewerPhotosSection({
    super.key,
    required this.imageUrls,
    this.onPhotoTap,
    this.shellMargin,
  });

  final List<String> imageUrls;
  final void Function(int index)? onPhotoTap;
  final EdgeInsets? shellMargin;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length <= 1) return const SizedBox.shrink();

    final extra = imageUrls.skip(1).toList();

    return PremiumProfileShell(
      margin: shellMargin ?? ProfileContentLayout.shellMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSectionHeader(
            title: 'More photos',
            subtitle: '${imageUrls.length} photos',
          ),
          const SizedBox(height: AppSpacing.spacingMD),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.82,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: extra.length,
            itemBuilder: (context, index) {
              final url = extra[index];
              return PremiumTapScale(
                onTap: onPhotoTap == null ? () {} : () => onPhotoTap!(index + 1),
                semanticLabel: 'Photo ${index + 2}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                  child: ProfileImageWidget(imageUrl: url, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileTapScale extends StatefulWidget {
  const _ProfileTapScale({
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  State<_ProfileTapScale> createState() => _ProfileTapScaleState();
}

class _ProfileTapScaleState extends State<_ProfileTapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed && AppAnimations.animationsEnabled(context) ? 0.96 : 1.0;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Builds categorized detail groups from profile field labels.
List<ProfileDetailGroup> buildCategorizedDetailGroups({
  String? gender,
  int? height,
  bool? smoke,
  bool? drink,
  bool? gym,
  List<String> jobs = const [],
  List<String> educations = const [],
  List<String> relationGoals = const [],
  List<String> preferredGenders = const [],
  List<String> languages = const [],
  List<String> musicGenres = const [],
}) {
  final groups = <ProfileDetailGroup>[];

  final identity = <ProfileDetailChipData>[];
  if (gender != null && gender.isNotEmpty) {
    identity.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('profile-circle'),
      label: 'Identity',
      value: gender,
    ));
  }
  if (height != null) {
    identity.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('ruler'),
      label: 'Height',
      value: '$height cm',
    ));
  }
  if (preferredGenders.isNotEmpty) {
    identity.add(ProfileDetailChipData(
      iconPath: AppIcons.heart,
      label: 'Interested in',
      value: preferredGenders.join(', '),
      accent: AppColors.accentPink,
    ));
  }
  if (identity.isNotEmpty) {
    groups.add(ProfileDetailGroup(
      title: 'Identity',
      iconPath: AppIcons.userOutline,
      chips: identity,
    ));
  }

  final lifestyle = <ProfileDetailChipData>[];
  if (smoke != null) {
    lifestyle.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('cloud'),
      label: 'Smoking',
      value: smoke ? 'Yes' : 'No',
    ));
  }
  if (drink != null) {
    lifestyle.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('glass'),
      label: 'Drinking',
      value: drink ? 'Yes' : 'No',
    ));
  }
  if (gym != null) {
    lifestyle.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('weight'),
      label: 'Fitness',
      value: gym ? 'Active' : 'Sometimes',
      accent: AppColors.warningYellow,
    ));
  }
  if (musicGenres.isNotEmpty) {
    lifestyle.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('musicnote'),
      label: 'Music',
      value: musicGenres.join(', '),
      accent: AppColors.feedbackInfo,
    ));
  }
  if (lifestyle.isNotEmpty) {
    groups.add(ProfileDetailGroup(
      title: 'Lifestyle',
      iconPath: AppIcons.getIconPath('weight'),
      chips: lifestyle,
    ));
  }

  final career = <ProfileDetailChipData>[];
  if (jobs.isNotEmpty) {
    career.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('briefcase'),
      label: 'Work',
      value: jobs.join(', '),
      accent: AppColors.feedbackInfo,
    ));
  }
  if (educations.isNotEmpty) {
    career.add(ProfileDetailChipData(
      iconPath: AppIcons.getIconPath('teacher'),
      label: 'Education',
      value: educations.join(', '),
    ));
  }
  if (career.isNotEmpty) {
    groups.add(ProfileDetailGroup(
      title: 'Career & education',
      iconPath: AppIcons.getIconPath('briefcase'),
      chips: career,
    ));
  }

  if (relationGoals.isNotEmpty) {
    groups.add(ProfileDetailGroup(
      title: 'Relationship goals',
      iconPath: AppIcons.heart,
      chips: [
        ProfileDetailChipData(
          iconPath: AppIcons.heart,
          label: 'Looking for',
          value: relationGoals.join(', '),
          accent: AppColors.accentPink,
        ),
      ],
    ));
  }

  if (languages.isNotEmpty) {
    groups.add(ProfileDetailGroup(
      title: 'Languages',
      iconPath: AppIcons.getIconPath('translate'),
      chips: [
        ProfileDetailChipData(
          iconPath: AppIcons.getIconPath('translate'),
          label: 'Speaks',
          value: languages.join(', '),
          accent: AppColors.feedbackSuccess,
        ),
      ],
    ));
  }

  return groups;
}

String? formatRecentlyActive(UserProfile profile) {
  final raw = profile.additionalData?['last_active_at'] ??
      profile.additionalData?['last_seen_at'] ??
      profile.additionalData?['last_active'];
  if (raw == null) return null;
  try {
    final dt = DateTime.parse(raw.toString()).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 5) return 'Active now';
    if (diff.inHours < 1) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return null;
  } catch (_) {
    return null;
  }
}
