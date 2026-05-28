// Widget: SwipeableCard
// Radical discovery profile card — cinematic photo + floating identity dock
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/profile_image_widget.dart';
import '../../features/profile/providers/profile_page_cache_provider.dart';

/// Profile card for discovery with a bold, editorial layout.
class SwipeableCard extends ConsumerStatefulWidget {
  final int userId;
  final String name;
  final int? age;
  final String? location;
  final String? avatarUrl;
  final List<String>? imageUrls;
  final String? bio;
  final bool isVerified;
  final bool isPremium;
  final double? distance;
  final int? compatibilityScore;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSuperlike;
  final VoidCallback? onViewProfile;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final List<String>? interests;
  final List<String>? sharedInterests;
  final String? jobTitle;
  final String? educationTitle;
  final bool isBackgroundPreview;

  const SwipeableCard({
    super.key,
    required this.userId,
    required this.name,
    this.age,
    this.location,
    this.avatarUrl,
    this.imageUrls,
    this.bio,
    this.isVerified = false,
    this.isPremium = false,
    this.distance,
    this.compatibilityScore,
    this.onLike,
    this.onDislike,
    this.onSuperlike,
    this.onViewProfile,
    this.isExpanded = false,
    this.onExpandedChanged,
    this.interests,
    this.sharedInterests,
    this.jobTitle,
    this.educationTitle,
    this.isBackgroundPreview = false,
  });

  static const double cardRadius = 28;

  @override
  ConsumerState<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends ConsumerState<SwipeableCard>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  late final AnimationController _expandController;
  late final Animation<double> _expandCurve;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 320),
      value: widget.isExpanded ? 1 : 0,
    );
    _expandCurve = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _currentImageIndex = 0;
    }
    if (oldWidget.isExpanded == widget.isExpanded) return;
    final shouldAnimate = !MediaQuery.of(context).disableAnimations;
    if (!shouldAnimate) {
      _expandController.value = widget.isExpanded ? 1 : 0;
      return;
    }
    if (widget.isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _cycleImage(int delta, int imageCount) {
    if (imageCount <= 1) return;
    setState(() {
      final nextIndex = _currentImageIndex + delta;
      if (nextIndex < 0 || nextIndex >= imageCount) return;
      _currentImageIndex = nextIndex;
    });
  }

  String _distanceLabel() {
    if (widget.distance != null) {
      return '${widget.distance!.round()} km away';
    }
    if (widget.location != null && widget.location!.isNotEmpty) {
      return widget.location!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myProfile = ref.watch(profilePageCacheProvider).valueOrNull?.profile;
    final myInterestSet = (myProfile?.interests ?? const <int>[])
        .map((e) => e.toString())
        .toSet();
    final images =
        widget.imageUrls ?? (widget.avatarUrl != null ? [widget.avatarUrl!] : []);
    final currentImage = images.isNotEmpty ? images[_currentImageIndex] : null;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final distanceLabel = _distanceLabel();
    final interests = widget.interests ?? const <String>[];
    final sharedInterests = (widget.sharedInterests ?? const <String>[])
        .map((e) => e.toLowerCase())
        .toSet();
    final matchPercentage = widget.compatibilityScore?.clamp(0, 100);
    final displayName = widget.name.trim().isEmpty ? 'User' : widget.name;

    return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingSM),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.45),
                theme.colorScheme.secondary.withValues(alpha: 0.2),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const collapsedPhotoFactor = 1.0;
                final expandedPhotoFactor =
                    (MediaQuery.sizeOf(context).height * 0.42 / constraints.maxHeight)
                        .clamp(0.38, 0.52);

                return AnimatedBuilder(
                  animation: _expandCurve,
                  builder: (context, child) {
                    final photoFactor = Tween<double>(
                      begin: collapsedPhotoFactor,
                      end: expandedPhotoFactor,
                    ).transform(_expandCurve.value);
                    final photoHeight = constraints.maxHeight * photoFactor;
                    final panelHeight = constraints.maxHeight - photoHeight;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: photoHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _PhotoStage(
                                currentImage: currentImage,
                                images: images,
                                disableAnimations: disableAnimations,
                                isBackgroundPreview: widget.isBackgroundPreview,
                                onCycleImage: _cycleImage,
                              ),
                              if (!widget.isBackgroundPreview) ...[
                                _PhotoChrome(
                                  matchPercentage: matchPercentage,
                                  imageCount: images.length,
                                  currentImageIndex: _currentImageIndex,
                                  onMoreTap: () =>
                                      widget.onExpandedChanged?.call(true),
                                  disableAnimations: disableAnimations,
                                ),
                                Positioned(
                                  left: AppSpacing.spacingMD,
                                  right: AppSpacing.spacingMD,
                                  bottom: AppSpacing.spacingMD,
                                  child: Opacity(
                                    opacity: 1 - _expandCurve.value * 0.85,
                                    child: IgnorePointer(
                                      ignoring: _expandCurve.value > 0.35,
                                      child: _IdentityDock(
                                        name: displayName,
                                        age: widget.age,
                                        distanceLabel: distanceLabel,
                                        isVerified: widget.isVerified,
                                        isPremium: widget.isPremium,
                                        onExpandTap: () => widget.onExpandedChanged
                                            ?.call(true),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!widget.isBackgroundPreview && panelHeight > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: panelHeight,
                            child: _ExpandPanel(
                              curve: _expandCurve,
                              name: displayName,
                              age: widget.age,
                              distanceLabel: distanceLabel,
                              bio: widget.bio,
                              isVerified: widget.isVerified,
                              isPremium: widget.isPremium,
                              matchPercentage: matchPercentage,
                              interests: interests,
                              sharedInterests: sharedInterests,
                              myInterestSet: myInterestSet,
                              jobTitle: widget.jobTitle,
                              educationTitle: widget.educationTitle,
                              onCollapse: () =>
                                  widget.onExpandedChanged?.call(false),
                              onViewProfile: widget.onViewProfile,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
    );
  }
}

class _PhotoStage extends StatelessWidget {
  const _PhotoStage({
    required this.currentImage,
    required this.images,
    required this.disableAnimations,
    required this.isBackgroundPreview,
    required this.onCycleImage,
  });

  final String? currentImage;
  final List<String> images;
  final bool disableAnimations;
  final bool isBackgroundPreview;
  final void Function(int delta, int count) onCycleImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: currentImage != null
              ? ProfileImageWidget(
                  key: ValueKey<String>(currentImage!),
                  imageUrl: currentImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              : ColoredBox(
                  key: const ValueKey<String>('fallback'),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: AppIcons.userOutline,
                      size: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.25, 0.72, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
          ),
        ),
        if (!isBackgroundPreview && images.length > 1)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onCycleImage(-1, images.length),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onCycleImage(1, images.length),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhotoChrome extends StatelessWidget {
  const _PhotoChrome({
    required this.matchPercentage,
    required this.imageCount,
    required this.currentImageIndex,
    required this.onMoreTap,
    required this.disableAnimations,
  });

  final int? matchPercentage;
  final int imageCount;
  final int currentImageIndex;
  final VoidCallback? onMoreTap;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        if (matchPercentage != null)
          Positioned(
            top: AppSpacing.spacingMD,
            left: AppSpacing.spacingMD,
            child: _MatchRing(percentage: matchPercentage!),
          ),
        if (imageCount > 1)
          Positioned(
            top: matchPercentage != null ? 78 : AppSpacing.spacingMD,
            left: AppSpacing.spacingMD,
            right: AppSpacing.spacingMD,
            child: _PhotoFilmstrip(
              count: imageCount,
              activeIndex: currentImageIndex,
              disableAnimations: disableAnimations,
            ),
          ),
        Positioned(
          top: AppSpacing.spacingMD,
          right: AppSpacing.spacingMD,
          child: Semantics(
            button: true,
            label: 'Expand profile details',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onMoreTap,
                child: Ink(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface.withValues(alpha: 0.55),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: AppIcons.getIconPath('more-circle'),
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchRing extends StatelessWidget {
  const _MatchRing({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$percentage%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PhotoFilmstrip extends StatelessWidget {
  const _PhotoFilmstrip({
    required this.count,
    required this.activeIndex,
    required this.disableAnimations,
  });

  final int count;
  final int activeIndex;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 3,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _IdentityDock extends StatelessWidget {
  const _IdentityDock({
    required this.name,
    required this.age,
    required this.distanceLabel,
    required this.isVerified,
    required this.isPremium,
    required this.onExpandTap,
  });

  final String name;
  final int? age;
  final String distanceLabel;
  final bool isVerified;
  final bool isPremium;
  final VoidCallback onExpandTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Expand profile details',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onExpandTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: theme.colorScheme.surface.withValues(alpha: 0.78),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                          ),
                          if (age != null) ...[
                            const SizedBox(width: AppSpacing.spacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '$age',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.onlineGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onlineGreen.withValues(alpha: 0.55),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isVerified || isPremium) ...[
                  const SizedBox(height: AppSpacing.spacingSM),
                  Row(
                    children: [
                      if (isVerified)
                        _StatusChip(
                          icon: AppIcons.verify,
                          label: 'Verified',
                          color: AppColors.onlineGreen,
                        ),
                      if (isVerified && isPremium)
                        const SizedBox(width: AppSpacing.spacingXS),
                      if (isPremium)
                        _StatusChip(
                          icon: AppIcons.star,
                          label: 'Premium',
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ],
                if (distanceLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.spacingSM),
                  Row(
                    children: [
                      AppSvgIcon(
                        assetPath: AppIcons.location,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          distanceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.spacingSM),
                Row(
                  children: [
                    Text(
                      'Swipe up for details',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    AppSvgIcon(
                      assetPath: AppIcons.arrowUp2,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(assetPath: icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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

class _ExpandPanel extends StatelessWidget {
  const _ExpandPanel({
    required this.curve,
    required this.name,
    required this.age,
    required this.distanceLabel,
    required this.bio,
    required this.isVerified,
    required this.isPremium,
    required this.matchPercentage,
    required this.interests,
    required this.sharedInterests,
    required this.myInterestSet,
    required this.jobTitle,
    required this.educationTitle,
    required this.onCollapse,
    required this.onViewProfile,
  });

  final Animation<double> curve;
  final String name;
  final int? age;
  final String distanceLabel;
  final String? bio;
  final bool isVerified;
  final bool isPremium;
  final int? matchPercentage;
  final List<String> interests;
  final Set<String> sharedInterests;
  final Set<String> myInterestSet;
  final String? jobTitle;
  final String? educationTitle;
  final VoidCallback onCollapse;
  final VoidCallback? onViewProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: SizeTransition(
        sizeFactor: curve,
        axisAlignment: -1,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        age != null ? '$name, $age' : name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Collapse profile details',
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onCollapse,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surfaceContainerHighest,
                              ),
                              child: AppSvgIcon(
                                assetPath: AppIcons.arrowDown,
                                size: 18,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isVerified || isPremium || matchPercentage != null) ...[
                  const SizedBox(height: AppSpacing.spacingSM),
                  Wrap(
                    spacing: AppSpacing.spacingXS,
                    runSpacing: AppSpacing.spacingXS,
                    children: [
                      if (isVerified)
                        _StatusChip(
                          icon: AppIcons.verify,
                          label: 'Verified',
                          color: AppColors.onlineGreen,
                        ),
                      if (isPremium)
                        _StatusChip(
                          icon: AppIcons.star,
                          label: 'Premium',
                          color: theme.colorScheme.primary,
                        ),
                      if (matchPercentage != null)
                        _StatusChip(
                          icon: AppIcons.heart,
                          label: '$matchPercentage% match',
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.spacingMD),
                if (distanceLabel.isNotEmpty)
                  _DetailRow(
                    icon: AppIcons.location,
                    label: distanceLabel,
                  ),
                if (bio != null && bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.spacingMD),
                  Text(
                    'About',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    bio!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
                      height: 1.4,
                    ),
                  ),
                ],
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.spacingLG),
                  Text(
                    'Interests',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingSM),
                  Wrap(
                    spacing: AppSpacing.spacingSM,
                    runSpacing: AppSpacing.spacingSM,
                    children: interests.map((interest) {
                      final isShared = sharedInterests.contains(
                            interest.toLowerCase(),
                          ) ||
                          myInterestSet.contains(interest);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isShared
                              ? theme.colorScheme.primary.withValues(alpha: 0.16)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(100),
                          border: isShared
                              ? Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
                                )
                              : null,
                        ),
                        child: Text(
                          interest,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isShared
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                            fontWeight:
                                isShared ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (jobTitle != null || educationTitle != null) ...[
                  const SizedBox(height: AppSpacing.spacingLG),
                  Text(
                    'Details',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacingSM),
                  if (jobTitle != null)
                    _DetailRow(icon: AppIcons.userTag, label: jobTitle!),
                  if (educationTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.spacingSM),
                      child: _DetailRow(
                        icon: AppIcons.award,
                        label: educationTitle!,
                      ),
                    ),
                ],
                if (onViewProfile != null) ...[
                  const SizedBox(height: AppSpacing.spacingLG),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onViewProfile,
                      child: const Text('View full profile'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
  });

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSvgIcon(
          assetPath: icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: AppSpacing.spacingSM),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ),
      ],
    );
  }
}
