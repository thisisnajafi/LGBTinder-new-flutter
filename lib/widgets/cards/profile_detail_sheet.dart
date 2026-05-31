import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icons.dart';
import '../../shared/models/match_reason.dart';
import 'swipeable_card.dart';

/// Draggable profile detail sheet shown when user taps bio "more".
class ProfileDetailSheet extends StatefulWidget {
  const ProfileDetailSheet({
    super.key,
    required this.controller,
    required this.profile,
    required this.sharedInterests,
    required this.onClose,
  });

  final DraggableScrollableController controller;
  final DiscoverySheetProfile profile;
  final Set<String> sharedInterests;
  final VoidCallback onClose;

  @override
  State<ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<ProfileDetailSheet> {
  bool _wasBelowSnap = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= notification.minExtent + 0.005) {
          if (_wasBelowSnap) {
            widget.onClose();
          }
          _wasBelowSnap = true;
        } else if (notification.extent > 0.55) {
          _wasBelowSnap = false;
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: widget.controller,
        initialChildSize: 0.58,
        minChildSize: 0.50,
        maxChildSize: 0.90,
        snap: true,
        snapSizes: const [0.58, 0.90],
        builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.20),
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
        );
      },
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
    this.isOnline = false,
    this.matchPercentage,
    this.matchReasons = const [],
    this.jobTitle,
    this.educationTitle,
    this.height,
    this.distance,
    this.interests = const [],
    this.imageUrls = const [],
  });

  final String firstName;
  final int? age;
  final String? city;
  final String? country;
  final String? bio;
  final bool isVerified;
  final bool isOnline;
  final int? matchPercentage;
  final List<MatchReason> matchReasons;
  final String? jobTitle;
  final String? educationTitle;
  final int? height;
  final double? distance;
  final List<String> interests;
  final List<String> imageUrls;
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
    final primary = theme.colorScheme.primary;
    final dividerColor = theme.colorScheme.outlineVariant;
    final surfaceVariant =
        theme.colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.age != null
                        ? '${profile.firstName}, ${profile.age}'
                        : profile.firstName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (profile.city != null || profile.country != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.getIconPath('location'),
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (profile.city != null) profile.city,
                              if (profile.country != null) profile.country,
                            ].join(', '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (profile.isVerified)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: primary, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.getIconPath('verify'),
                      size: 12,
                      color: primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (profile.isOnline)
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
                      ),
                    ),
                  ],
                ),
              ),
            if (profile.matchPercentage != null &&
                profile.matchPercentage! > 0)
              _StatChip(
                background: primary.withValues(alpha: 0.12),
                border: primary.withValues(alpha: 0.40),
                child: Text(
                  'Match ${profile.matchPercentage}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'About',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.6,
            ),
          ),
        ],
        if (profile.matchReasons.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Why you matched',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.matchReasons.map((reason) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.30),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(
                      assetPath: matchReasonIconPath(reason.type),
                      size: 16,
                      color: primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      reason.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        if (_hasInfoPills(profile)) ...[
          const SizedBox(height: 24),
          Text(
            'Info',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                _InfoPill(
                  icon: AppIcons.getIconPath('location'),
                  label: '${profile.distance!.round()} km away',
                  surfaceVariant: surfaceVariant,
                  dividerColor: dividerColor,
                ),
            ],
          ),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Interests',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.interests.map((interest) {
              final isShared =
                  sharedInterests.contains(interest.toLowerCase());
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isShared
                      ? primary.withValues(alpha: 0.15)
                      : surfaceVariant,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isShared
                        ? primary.withValues(alpha: 0.50)
                        : dividerColor,
                    width: isShared ? 1 : 0.5,
                  ),
                ),
                child: Text(
                  interest,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isShared
                        ? primary
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
          const SizedBox(height: 24),
          Text(
            'Photos',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: profile.imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
        profile.distance != null;
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    final primary = theme.colorScheme.primary;

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
            color: primary.withValues(alpha: 0.70),
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

/// Floating discovery action buttons shown over the profile detail sheet.
class DiscoveryFloatingActions extends StatelessWidget {
  const DiscoveryFloatingActions({
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
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom + 16;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedOpacity(
          opacity: disabled ? 0.5 : 1,
          duration: const Duration(milliseconds: 150),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FloatingActionButton(
                icon: AppIcons.getIconPath('close-circle'),
                fillColor: AppColors.feedbackError,
                size: 58,
                onPressed: disabled ? null : onDislike,
                semanticLabel: 'Dislike profile',
              ),
              const SizedBox(width: 32),
              _FloatingActionButton(
                icon: AppIcons.star,
                fillColor: theme.colorScheme.primary,
                size: 54,
                onPressed: disabled ? null : onSuperlike,
                semanticLabel: 'Super like profile',
              ),
              const SizedBox(width: 32),
              _FloatingActionButton(
                icon: AppIcons.heart,
                fillColor: AppColors.feedbackSuccess,
                size: 58,
                onPressed: disabled ? null : onLike,
                semanticLabel: 'Like profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton({
    required this.icon,
    required this.fillColor,
    required this.size,
    required this.onPressed,
    required this.semanticLabel,
  });

  final String icon;
  final Color fillColor;
  final double size;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Material(
        color: fillColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AppSvgIcon(
                assetPath: icon,
                size: size * 0.42,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
