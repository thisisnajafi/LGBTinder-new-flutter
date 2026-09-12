import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/match_percentage_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/premium/premium_design_system.dart';
import '../discovery/discovery_swipe_action_button.dart';
import '../../shared/models/match_reason.dart';
import '../../features/profile/data/models/profile_verification.dart';
import '../ui/distance_tag.dart';
import '../verification/verification_components.dart';
import 'swipeable_card.dart';

/// Draggable profile detail sheet shown when user swipes up or taps bio "more".
class ProfileDetailSheet extends StatefulWidget {
  const ProfileDetailSheet({
    super.key,
    required this.controller,
    required this.profile,
    required this.sharedInterests,
    required this.onClose,
    this.onDislike,
    this.onSuperlike,
    this.onLike,
    this.actionsDisabled = false,
  });

  final DraggableScrollableController controller;
  final DiscoverySheetProfile profile;
  final Set<String> sharedInterests;
  final VoidCallback onClose;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onLike;
  final bool actionsDisabled;

  @override
  State<ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<ProfileDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent < 0.52) {
          widget.onClose();
        }
        return false;
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppBreakpoints.isPhone(context)
                ? double.infinity
                : ResponsiveGrid.maxContentWidth(context),
          ),
          child: DraggableScrollableSheet(
        controller: widget.controller,
        initialChildSize: 0.60,
        minChildSize: 0.50,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.60, 0.92],
        builder: (context, scrollController) {
          final showActions = widget.onDislike != null ||
              widget.onSuperlike != null ||
              widget.onLike != null;
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return DecoratedBox(
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusXL),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.accentViolet.withValues(alpha: 0.22),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.spacingLG,
                      0,
                      AppSpacing.spacingLG,
                      showActions
                          ? AppSpacing.spacingXL
                          : AppSpacing.spacingXXL + bottomInset,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(
                            top: AppSpacing.spacingMD,
                            bottom: AppSpacing.spacingLG,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      ProfileSheetContent(
                        profile: widget.profile,
                        sharedInterests: widget.sharedInterests,
                      ),
                    ],
                  ),
                ),
                if (showActions)
                  _SheetActionFooter(
                    disabled: widget.actionsDisabled,
                    onDislike: widget.onDislike,
                    onSuperlike: widget.onSuperlike,
                    onLike: widget.onLike,
                    sheetColor: sheetColor,
                    bottomInset: bottomInset,
                  ),
              ],
            ),
          );
        },
      ),
        ),
      ),
    );
  }
}

/// Profile data for the detail sheet.
class DiscoverySheetProfile {
  const DiscoverySheetProfile({
    required this.firstName,
    this.age,
    this.city,
    this.country,
    this.bio,
    this.isVerified = false,
    this.verification,
    this.isOnline = false,
    this.matchPercentage,
    this.matchReasons = const [],
    this.jobTitle,
    this.educationTitle,
    this.height,
    this.distance,
    this.interests = const [],
    this.imageUrls = const [],
    this.smoke,
    this.drink,
    this.gym,
    this.languages = const [],
    this.musicGenres = const [],
    this.relationshipGoal,
  });

  final String firstName;
  final int? age;
  final String? city;
  final String? country;
  final String? bio;
  final bool isVerified;
  final ProfileIdentityVerification? verification;
  final bool isOnline;
  final int? matchPercentage;
  final List<MatchReason> matchReasons;
  final String? jobTitle;
  final String? educationTitle;
  final int? height;
  final double? distance;
  final List<String> interests;
  final List<String> imageUrls;
  final String? smoke;
  final String? drink;
  final String? gym;
  final List<String> languages;
  final List<String> musicGenres;
  final String? relationshipGoal;
}

class ProfileSheetContent extends StatelessWidget {
  const ProfileSheetContent({
    super.key,
    required this.profile,
    required this.sharedInterests,
  });

  final DiscoverySheetProfile profile;
  final Set<String> sharedInterests;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.accentViolet;
    final dividerColor = theme.colorScheme.outlineVariant;
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumShell(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      profile.age != null
                          ? '${profile.firstName}, ${profile.age}'
                          : profile.firstName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                    ),
                    if (profile.city != null || profile.country != null) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      Row(
                        children: [
                          AppSvgIcon(
                            assetPath: AppIcons.getIconPath('location'),
                            size: 14,
                            color: accent,
                          ),
                          const SizedBox(width: AppSpacing.spacingXS),
                          Expanded(
                            child: AppText(
                              [
                                if (profile.city != null) profile.city,
                                if (profile.country != null) profile.country,
                              ].join(', '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.65),
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (profile.matchPercentage != null &&
                        profile.matchPercentage! > 0) ...[
                      const SizedBox(height: AppSpacing.spacingSM),
                      _MatchSheetChip(percentage: profile.matchPercentage!),
                    ],
                    if (profile.verification != null &&
                        profile.verification!.hasAnyVerified) ...[
                      const SizedBox(height: AppSpacing.spacingXS),
                      VerificationStatusRow(
                        photoVerified: profile.verification!.photoVerified,
                        idVerified: profile.verification!.idVerified,
                        videoVerified: profile.verification!.videoVerified,
                      ),
                    ],
                  ],
                ),
              ),
              if (profile.verification != null &&
                  profile.verification!.badge != 'Unverified')
                VerificationBadgeChip(
                  badge: profile.verification!.badge,
                  compact: true,
                )
              else if (profile.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacingSM,
                    vertical: AppSpacing.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: accent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.getIconPath('verify'),
                        size: 12,
                        color: accent,
                      ),
                      const SizedBox(width: AppSpacing.spacingXS),
                      Text(
                        'Verified',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (profile.isOnline) ...[
          const SizedBox(height: AppSpacing.spacingLG),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: [
              _StatChip(
                background: kDiscoveryOnlineGreen.withValues(alpha: 0.12),
                border: kDiscoveryOnlineGreen.withValues(alpha: 0.40),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: kDiscoveryOnlineGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online now',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: kDiscoveryOnlineGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.spacingXL),
          const PremiumSectionHeader(title: 'About'),
          const SizedBox(height: AppSpacing.spacingSM),
          Text(
            profile.bio!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
        ],
        if (profile.matchReasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.spacingXL),
          const PremiumSectionHeader(title: 'Why you matched'),
          const SizedBox(height: AppSpacing.spacingSM),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: profile.matchReasons.map((reason) {
              return _MatchReasonChip(reason: reason);
            }).toList(),
          ),
        ],
        if (_hasInfoPills(profile)) ...[
          const SizedBox(height: AppSpacing.spacingXL),
          const PremiumSectionHeader(title: 'Info'),
          const SizedBox(height: AppSpacing.spacingSM),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: [
              if (profile.jobTitle != null)
                _InfoPill(
                  icon: AppIcons.getIconPath('briefcase'),
                  label: profile.jobTitle!,
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.educationTitle != null)
                _InfoPill(
                  icon: AppIcons.getIconPath('teacher'),
                  label: profile.educationTitle!,
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.height != null)
                _InfoPill(
                  icon: AppIcons.getIconPath('ruler'),
                  label: '${profile.height} cm',
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.distance != null)
                DistanceTag(distance: profile.distance!),
              if (profile.smoke != null)
                _InfoPill(
                  icon: AppIcons.getIconPath('health'),
                  label: 'Smokes: ${profile.smoke}',
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.drink != null)
                _InfoPill(
                  icon: AppIcons.getIconPath('coffee'),
                  label: 'Drinks: ${profile.drink}',
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.gym != null)
                _InfoPill(
                  icon: AppIcons.getIconPath('weight'),
                  label: 'Gym: ${profile.gym}',
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.relationshipGoal != null)
                _InfoPill(
                  icon: AppIcons.getIconPath('lovely'),
                  label: profile.relationshipGoal!,
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.languages.isNotEmpty)
                _InfoPill(
                  icon: AppIcons.getIconPath('language-circle'),
                  label: profile.languages.join(', '),
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
              if (profile.musicGenres.isNotEmpty)
                _InfoPill(
                  icon: AppIcons.getIconPath('music'),
                  label: profile.musicGenres.join(', '),
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
            ],
          ),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.spacingXL),
          const PremiumSectionHeader(title: 'Interests'),
          const SizedBox(height: AppSpacing.spacingSM),
          Wrap(
            spacing: AppSpacing.spacingSM,
            runSpacing: AppSpacing.spacingSM,
            children: profile.interests.map((interest) {
              final isShared =
                  sharedInterests.contains(interest.toLowerCase());
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isShared
                      ? accent.withValues(alpha: 0.15)
                      : surfaceVariant,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isShared
                        ? accent.withValues(alpha: 0.50)
                        : dividerColor,
                    width: isShared ? 1 : 0.5,
                  ),
                ),
                child: Text(
                  interest,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isShared
                        ? accent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight:
                        isShared ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (profile.imageUrls.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.spacingXL),
          const PremiumSectionHeader(title: 'Photos'),
          const SizedBox(height: AppSpacing.spacingSM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveGrid.photoColumns(context),
              childAspectRatio: 1,
              mainAxisSpacing: AppSpacing.spacingXS,
              crossAxisSpacing: AppSpacing.spacingXS,
            ),
            itemCount: profile.imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                child: CachedNetworkImage(
                  imageUrl: profile.imageUrls[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  bool _hasInfoPills(DiscoverySheetProfile profile) {
    return profile.jobTitle != null ||
        profile.educationTitle != null ||
        profile.height != null ||
        profile.distance != null ||
        profile.smoke != null ||
        profile.drink != null ||
        profile.gym != null ||
        profile.relationshipGoal != null ||
        profile.languages.isNotEmpty ||
        profile.musicGenres.isNotEmpty;
  }
}

class _MatchSheetChip extends StatelessWidget {
  const _MatchSheetChip({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = MatchPercentageColors.colorFor(percentage);

    return _StatChip(
      background: color.withValues(alpha: 0.14),
      border: color.withValues(alpha: 0.45),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: AppIcons.getIconPath('magic-star'),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            'Match $percentage%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchReasonChip extends StatelessWidget {
  const _MatchReasonChip({required this.reason});

  final MatchReason reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.accentViolet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: matchReasonIconPath(reason.type),
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 5),
          Text(
            reason.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.background,
    required this.border,
    required this.child,
  });

  final Color background;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border, width: 0.5),
      ),
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.surfaceVariant,
    required this.dividerColor,
  });

  final String icon;
  final String label;
  final Color surfaceVariant;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.accentViolet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: icon,
            size: 16,
            color: accent.withValues(alpha: 0.70),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Like / superlike / dislike footer that sits on the sheet and covers the nav bar.
class _SheetActionFooter extends StatelessWidget {
  const _SheetActionFooter({
    required this.disabled,
    required this.onDislike,
    required this.onSuperlike,
    required this.onLike,
    required this.sheetColor,
    required this.bottomInset,
  });

  final bool disabled;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onLike;
  final Color sheetColor;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sheetColor.withValues(alpha: 0),
            sheetColor,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.accentViolet.withValues(alpha: isDark ? 0.22 : 0.14),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.spacingXL,
          AppSpacing.spacingMD,
          AppSpacing.spacingXL,
          AppSpacing.spacingMD + bottomInset,
        ),
        child: DiscoverySheetActionBar(
          disabled: disabled,
          onDislike: onDislike,
          onSuperlike: onSuperlike,
          onLike: onLike,
        ),
      ),
    );
  }
}

/// Like / superlike / dislike buttons pinned to the profile detail sheet footer.
class DiscoverySheetActionBar extends StatelessWidget {
  const DiscoverySheetActionBar({
    super.key,
    required this.onDislike,
    required this.onSuperlike,
    required this.onLike,
    this.disabled = false,
  });

  final VoidCallback? onDislike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onLike;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final actionGap = AppBreakpoints.value(
      context,
      phone: AppSpacing.spacingLG,
      tablet: AppSpacing.spacingXXL,
    );

    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1,
      duration: const Duration(milliseconds: 150),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiscoverySwipeActionButton(
            type: DiscoverySwipeActionType.dislike,
            size: 58,
            onPressed: disabled ? null : onDislike,
          ),
          SizedBox(width: actionGap),
          DiscoverySwipeActionButton(
            type: DiscoverySwipeActionType.superlike,
            size: 54,
            onPressed: disabled ? null : onSuperlike,
          ),
          SizedBox(width: actionGap),
          DiscoverySwipeActionButton(
            type: DiscoverySwipeActionType.like,
            size: 58,
            onPressed: disabled ? null : onLike,
          ),
        ],
      ),
    );
  }
}
