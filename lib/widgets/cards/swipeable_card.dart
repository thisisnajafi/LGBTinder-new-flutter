// Widget: SwipeableCard — full-bleed discovery profile card (Phase 1 spec)
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icons.dart';
import '../../shared/models/match_reason.dart';

/// Online status indicator — functional color permitted by design spec.
const Color kDiscoveryOnlineGreen = Color(0xFF22C55E);

/// Profile card for discovery with photo overlay identity block.
class SwipeableCard extends ConsumerStatefulWidget {
  final int userId;
  final String name;
  final int? age;
  final String? city;
  final String? country;
  final String? avatarUrl;
  final List<String>? imageUrls;
  final String? bio;
  final bool isVerified;
  final bool isPremium;
  final bool isOnline;
  final double? distance;
  final int? matchPercentage;
  final List<MatchReason> matchReasons;
  final VoidCallback? onBioMoreTap;
  final VoidCallback? onProfileTap;
  final bool isExpanded;
  final bool isBackgroundPreview;
  final bool hideBioMore;

  const SwipeableCard({
    super.key,
    required this.userId,
    required this.name,
    this.age,
    this.city,
    this.country,
    this.avatarUrl,
    this.imageUrls,
    this.bio,
    this.isVerified = false,
    this.isPremium = false,
    this.isOnline = false,
    this.distance,
    this.matchPercentage,
    this.matchReasons = const [],
    this.onBioMoreTap,
    this.onProfileTap,
    this.isExpanded = false,
    this.isBackgroundPreview = false,
    this.hideBioMore = false,
  });

  static const double cardRadius = 28;
  static const double cardAspectRatio = 0.62;
  static const Duration imageCarouselInterval = Duration(seconds: 5);

  @override
  ConsumerState<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends ConsumerState<SwipeableCard>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  Timer? _imageCarouselTimer;
  int _carouselGeneration = 0;
  late final AnimationController _headerController;
  late final Animation<double> _headerCurve;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 380),
      value: widget.isExpanded ? 1 : 0,
    );
    _headerCurve = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _scheduleImageCarousel();
  }

  @override
  void didUpdateWidget(covariant SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _currentImageIndex = 0;
      _scheduleImageCarousel();
    } else if (oldWidget.imageUrls != widget.imageUrls ||
        oldWidget.avatarUrl != widget.avatarUrl) {
      _scheduleImageCarousel();
    }
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _stopImageCarousel();
      } else {
        _scheduleImageCarousel();
      }
    }
    if (oldWidget.isExpanded == widget.isExpanded) return;
    final shouldAnimate = !MediaQuery.of(context).disableAnimations;
    if (!shouldAnimate) {
      _headerController.value = widget.isExpanded ? 1 : 0;
      return;
    }
    if (widget.isExpanded) {
      _headerController.forward();
    } else {
      _headerController.reverse();
    }
  }

  @override
  void deactivate() {
    _stopImageCarousel();
    super.deactivate();
  }

  @override
  void dispose() {
    _stopImageCarousel();
    _headerController.dispose();
    super.dispose();
  }

  void _scheduleImageCarousel() {
    _stopImageCarousel();
    if (!mounted || widget.isBackgroundPreview || widget.isExpanded) return;

    final count = _images.length;
    if (count <= 1) return;

    if (MediaQuery.of(context).disableAnimations) return;

    final generation = ++_carouselGeneration;
    _imageCarouselTimer = Timer.periodic(
      SwipeableCard.imageCarouselInterval,
      (_) {
        if (!mounted || generation != _carouselGeneration) return;
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % count;
        });
      },
    );
  }

  void _stopImageCarousel() {
    _carouselGeneration++;
    _imageCarouselTimer?.cancel();
    _imageCarouselTimer = null;
  }

  void _cycleImage(int delta, int imageCount) {
    if (imageCount <= 1) return;
    setState(() {
      final nextIndex = _currentImageIndex + delta;
      if (nextIndex < 0) {
        _currentImageIndex = imageCount - 1;
      } else if (nextIndex >= imageCount) {
        _currentImageIndex = 0;
      } else {
        _currentImageIndex = nextIndex;
      }
    });
    _scheduleImageCarousel();
  }

  List<String> get _images {
    final seen = <String>{};
    final list = <String>[];
    for (final url in widget.imageUrls ?? const <String>[]) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      list.add(trimmed);
    }
    final avatar = widget.avatarUrl?.trim();
    if (avatar != null && avatar.isNotEmpty && seen.add(avatar)) {
      if (list.isEmpty) {
        list.add(avatar);
      } else if (!list.contains(avatar)) {
        list.insert(0, avatar);
      }
    }
    return list;
  }

  Border? _cardBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: widget.isBackgroundPreview
          ? (isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight)
          : (isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight),
      width: widget.isBackgroundPreview ? 1 : 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final currentImage = images.isNotEmpty ? images[_currentImageIndex] : null;
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final displayName = widget.name.trim().isEmpty ? 'User' : widget.name.trim();
    final matchPct = widget.matchPercentage;
    final cardReasons = widget.matchReasons.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final expandedHeaderHeight = screenHeight * 0.45;
        final fullHeight = constraints.maxWidth / SwipeableCard.cardAspectRatio;

        return AnimatedBuilder(
          animation: _headerCurve,
          builder: (context, child) {
            final height = Tween<double>(
              begin: fullHeight,
              end: expandedHeaderHeight,
            ).transform(_headerCurve.value);

            return SizedBox(
              height: height.clamp(0, constraints.maxHeight),
              width: constraints.maxWidth,
              child: child,
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
              border: _cardBorder(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
              child: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoLayer(
                  currentImage: currentImage,
                  images: images,
                  disableAnimations: disableAnimations,
                  isBackgroundPreview: widget.isBackgroundPreview,
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: _PhotoGradientOverlay(),
                  ),
                ),
                if (!widget.isBackgroundPreview && images.length > 1)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 56,
                    bottom: 120,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _cycleImage(1, images.length),
                    ),
                  ),
                if (!widget.isBackgroundPreview) ...[
                  if (matchPct != null && matchPct > 0)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _MatchPercentageBadge(percentage: matchPct),
                    ),
                  if (cardReasons.isNotEmpty)
                    Positioned(
                      top: matchPct != null && matchPct > 0 ? 52 : 14,
                      left: 14,
                      right: 56,
                      child: _MatchReasonBadges(reasons: cardReasons),
                    ),
                  if (images.length > 1)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: _PhotoStripIndicator(
                        count: images.length,
                        activeIndex: _currentImageIndex,
                        disableAnimations: disableAnimations,
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _BottomTextBlock(
                      name: displayName,
                      age: widget.age,
                      city: widget.city,
                      bio: widget.bio,
                      isOnline: widget.isOnline,
                      hideBioMore: widget.hideBioMore || widget.isExpanded,
                      onBioMoreTap: widget.onBioMoreTap,
                      onProfileTap: widget.onProfileTap,
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoLayer extends ConsumerWidget {
  const _PhotoLayer({
    required this.currentImage,
    required this.images,
    required this.disableAnimations,
    required this.isBackgroundPreview,
  });

  final String? currentImage;
  final List<String> images;
  final bool disableAnimations;
  final bool isBackgroundPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cacheManager = ref.watch(imageCacheServiceProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final memCacheWidth = isBackgroundPreview
        ? 280
        : (screenWidth * dpr).round().clamp(560, 1400);

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration:
              disableAnimations ? Duration.zero : const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: currentImage != null
              ? CachedNetworkImage(
                  key: ValueKey<String>(currentImage!),
                  imageUrl: currentImage!,
                  cacheManager: cacheManager,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  memCacheWidth: memCacheWidth,
                  fadeInDuration: const Duration(milliseconds: 180),
                  fadeOutDuration: const Duration(milliseconds: 120),
                  placeholder: (context, url) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: AppSvgIcon(
                        assetPath: AppIcons.userOutline,
                        size: 72,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
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
      ],
    );
  }
}

class _PhotoGradientOverlay extends StatelessWidget {
  const _PhotoGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.38, 0.68, 1.0],
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0.88),
          ],
        ),
      ),
    );
  }
}

class _MatchPercentageBadge extends StatelessWidget {
  const _MatchPercentageBadge({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Match $percentage%',
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MatchReasonBadges extends StatelessWidget {
  const _MatchReasonBadges({required this.reasons});

  final List<MatchReason> reasons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: reasons.map((reason) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSvgIcon(
                assetPath: matchReasonIconPath(reason.type),
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                reason.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoStripIndicator extends StatelessWidget {
  const _PhotoStripIndicator({
    required this.count,
    required this.activeIndex,
    required this.disableAnimations,
  });

  final int count;
  final int activeIndex;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Padding(
          padding: EdgeInsets.only(bottom: index < count - 1 ? 4 : 0),
          child: AnimatedContainer(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 4,
            height: isActive ? 28 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }
}

class _BottomTextBlock extends StatelessWidget {
  const _BottomTextBlock({
    required this.name,
    required this.age,
    required this.city,
    required this.bio,
    required this.isOnline,
    required this.hideBioMore,
    required this.onBioMoreTap,
    required this.onProfileTap,
  });

  final String name;
  final int? age;
  final String? city;
  final String? bio;
  final bool isOnline;
  final bool hideBioMore;
  final VoidCallback? onBioMoreTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedBio = bio?.trim() ?? '';
    final openProfile = onProfileTap ?? onBioMoreTap;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openProfile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      age != null ? '$name, $age' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isOnline) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Online now',
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: kDiscoveryOnlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (city != null && city!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.getIconPath('location'),
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (trimmedBio.isNotEmpty && !hideBioMore) ...[
                const SizedBox(height: 8),
                _BioPreview(
                  bio: trimmedBio,
                  onMoreTap: openProfile,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BioPreview extends StatelessWidget {
  const _BioPreview({
    required this.bio,
    required this.onMoreTap,
  });

  final String bio;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bio.length <= 60) {
      return Text(
        bio,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.75),
        ),
      );
    }

    final preview = bio.substring(0, 60);
    return Text.rich(
      TextSpan(
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.75),
        ),
        children: [
          TextSpan(text: '$preview... '),
          TextSpan(
            text: 'more',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()..onTap = onMoreTap,
          ),
        ],
      ),
      maxLines: 3,
    );
  }
}

/// Maps match reason type to SVG asset path.
String matchReasonIconPath(String type) {
  switch (type) {
    case 'music':
      return AppIcons.getIconPath('musicnote');
    case 'interests':
      return AppIcons.getIconPath('heart');
    case 'location':
      return AppIcons.getIconPath('location');
    case 'job':
      return AppIcons.getIconPath('briefcase');
    case 'education':
      return AppIcons.getIconPath('teacher');
    case 'age':
      return AppIcons.getIconPath('calendar');
    default:
      return AppIcons.getIconPath('star');
  }
}
