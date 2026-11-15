// Widget: SwipeableCard — full-bleed discovery profile card (Phase 1 spec)
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/match_percentage_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/optimized_image.dart';
import '../../features/discover/utils/discovery_image_prefetch.dart';
import '../../shared/models/match_reason.dart';
import '../ui/distance_tag.dart';
import '../../core/responsive/responsive.dart';

/// Online status indicator — functional color permitted by design spec.
const Color kDiscoveryOnlineGreen = Color(0xFF22C55E);

/// Distance from the card's top edge to the photo indicator.
const double _kCardTopInset = 10;

/// Distance from the card's side edges to overlays (chips, indicator).
const double _kCardSideInset = 14;

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
  final bool isSuperliked;
  final bool isOnline;
  final double? distance;
  final int? matchPercentage;
  final List<MatchReason> matchReasons;
  final VoidCallback? onBioMoreTap;
  final VoidCallback? onProfileTap;
  final bool isExpanded;
  final bool isBackgroundPreview;
  final bool hideBioMore;

  /// When false (e.g. Discover tab off-screen), the photo carousel timer stops.
  final bool carouselEnabled;

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
    this.isSuperliked = false,
    this.isOnline = false,
    this.distance,
    this.matchPercentage,
    this.matchReasons = const [],
    this.onBioMoreTap,
    this.onProfileTap,
    this.isExpanded = false,
    this.isBackgroundPreview = false,
    this.hideBioMore = false,
    this.carouselEnabled = true,
  });

  static const double cardRadius = AppRadius.radiusXL;

  /// Decode width used for both the front card and cards behind it so a swipe
  /// can reuse the in-memory image instead of fetching a larger copy.
  static int photoDecodeWidth(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    return (screenWidth * dpr).round().clamp(560, 1400);
  }

  /// Wider/shorter discover card (width ÷ height).
  static const double cardAspectRatio = 0.76;
  static const Duration imageCarouselInterval = Duration(seconds: 5);

  /// Uses full [maxWidth]; height follows aspect ratio, capped so vertical centering keeps margin.
  /// Tallest allowed card shape (width / height). Between this and
  /// [cardAspectRatio] the card stretches to fill the available height, so
  /// tall phones get a much bigger card instead of a small letterboxed one.
  static const double minCardAspectRatio = 0.56;

  /// Largest card that fits [maxWidth] x [maxHeight] (minus
  /// [minimumVerticalMargin]). Uses the full width, and the full height as long
  /// as the shape stays between [minCardAspectRatio] and [cardAspectRatio].
  static Size fitSize({
    required double maxWidth,
    required double maxHeight,
    double minimumVerticalMargin = 0,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0) return Size.zero;

    final maxCardHeight =
        (maxHeight - minimumVerticalMargin).clamp(0.0, maxHeight);
    if (maxCardHeight <= 0) return Size.zero;

    var width = maxWidth;
    final tallest = width / minCardAspectRatio;
    final shortest = width / cardAspectRatio;
    var height = maxCardHeight.clamp(0.0, tallest);
    if (height < shortest) {
      // Not enough height even for the widest shape: shrink the width.
      width = height * cardAspectRatio;
    }
    return Size(width, height);
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleImageCarousel();
      _precacheNeighbourPhoto();
    });
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
    if (oldWidget.isExpanded != widget.isExpanded ||
        oldWidget.carouselEnabled != widget.carouselEnabled ||
        oldWidget.isBackgroundPreview != widget.isBackgroundPreview) {
      if (widget.isExpanded ||
          !widget.carouselEnabled ||
          widget.isBackgroundPreview) {
        _stopImageCarousel();
      } else {
        _scheduleImageCarousel();
      }
    }
    if (oldWidget.isBackgroundPreview && !widget.isBackgroundPreview) {
      // Promoted to the front: get the second photo ready.
      _precacheNeighbourPhoto();
    }
    if (oldWidget.isExpanded == widget.isExpanded) return;
    final shouldAnimate = !MediaQuery.disableAnimationsOf(context);
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
    if (!mounted ||
        widget.isBackgroundPreview ||
        widget.isExpanded ||
        !widget.carouselEnabled) {
      return;
    }

    final count = _images.length;
    if (count <= 1) return;

    if (MediaQuery.disableAnimationsOf(context)) return;

    final generation = ++_carouselGeneration;
    _imageCarouselTimer = Timer.periodic(
      SwipeableCard.imageCarouselInterval,
      (_) {
        if (!mounted || generation != _carouselGeneration) return;
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % count;
        });
        _precacheNeighbourPhoto();
      },
    );
  }

  /// Decodes the photo after the current one, at the size the card shows it,
  /// so switching photos does not flash the placeholder.
  void _precacheNeighbourPhoto() {
    if (!mounted || widget.isBackgroundPreview) return;
    final images = _images;
    if (images.length <= 1) return;
    final next = (_currentImageIndex + 1) % images.length;
    unawaited(
      DiscoveryImagePrefetch.precacheCardPhoto(
        context,
        images[next],
        decodeWidth: SwipeableCard.photoDecodeWidth(context),
      ),
    );
  }

  void _stopImageCarousel() {
    _carouselGeneration++;
    _imageCarouselTimer?.cancel();
    _imageCarouselTimer = null;
  }

  void _cycleImage(int delta, int imageCount) {
    if (imageCount <= 1) return;
    final nextIndex = (_currentImageIndex + delta).clamp(0, imageCount - 1);
    if (nextIndex == _currentImageIndex) return;
    AppHaptics.selection();
    setState(() => _currentImageIndex = nextIndex);
    _scheduleImageCarousel();
    _precacheNeighbourPhoto();
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

  @override
  Widget build(BuildContext context) {
    final images = _images;
    // Guard against a shorter photo list after a feed refresh.
    if (_currentImageIndex >= images.length) _currentImageIndex = 0;
    final currentImage = images.isNotEmpty ? images[_currentImageIndex] : null;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final displayName = widget.name.trim().isEmpty ? 'User' : widget.name.trim();
    final matchPct = widget.matchPercentage;
    final hasMatchChip = matchPct != null && matchPct > 0;
    final hasChips =
        hasMatchChip || widget.isSuperliked || widget.matchReasons.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final fitted = SwipeableCard.fitSize(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );
        final cardWidth = fitted.width;
        final fullHeight = fitted.height;
        final expandedHeaderHeight =
            (screenHeight * 0.45).clamp(0.0, constraints.maxHeight);
        final textBottomInset = math.max(18.0, fullHeight * 0.04);

        return AnimatedBuilder(
          animation: _headerCurve,
          builder: (context, child) {
            final height = Tween<double>(
              begin: fullHeight,
              end: expandedHeaderHeight,
            ).transform(_headerCurve.value);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: height.clamp(0, constraints.maxHeight),
                width: cardWidth,
                child: child,
              ),
            );
          },
          child: RepaintBoundary(
            child: _DiscoveryCardFrame(
            matchPct: matchPct,
            isBackgroundPreview: widget.isBackgroundPreview,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
              child: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoLayer(
                  currentImage: currentImage,
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
                    right: 0,
                    bottom: 120,
                    // A Row follows the text direction, so "previous" is on
                    // the leading half in both LTR and RTL.
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _cycleImage(-1, images.length),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _cycleImage(1, images.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!widget.isBackgroundPreview) ...[
                  if (images.length > 1)
                    PositionedDirectional(
                      top: _kCardTopInset,
                      start: _kCardSideInset,
                      end: _kCardSideInset,
                      child: IgnorePointer(
                        child: _PhotoSegmentIndicator(
                          count: images.length,
                          activeIndex: _currentImageIndex,
                        ),
                      ),
                    ),
                  if (hasChips)
                    PositionedDirectional(
                      top: images.length > 1
                          ? _kCardTopInset +
                              _PhotoSegmentIndicator.height +
                              AppSpacing.spacingSM
                          : _kCardSideInset,
                      start: _kCardSideInset,
                      end: _kCardSideInset,
                      child: IgnorePointer(
                        child: _CardChips(
                          matchPercentage: hasMatchChip ? matchPct : null,
                          isSuperliked: widget.isSuperliked,
                          reasons: widget.matchReasons,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: textBottomInset,
                    child: _BottomTextBlock(
                      name: displayName,
                      age: widget.age,
                      city: widget.city,
                      distance: widget.distance,
                      bio: widget.bio,
                      isOnline: widget.isOnline,
                      isVerified: widget.isVerified,
                      isPremium: widget.isPremium,
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
          ),
        );
      },
    );
  }
}

class _DiscoveryCardFrame extends StatelessWidget {
  const _DiscoveryCardFrame({
    required this.child,
    required this.matchPct,
    required this.isBackgroundPreview,
  });

  final Widget child;
  final int? matchPct;
  final bool isBackgroundPreview;

  @override
  Widget build(BuildContext context) {
    final radius = SwipeableCard.cardRadius;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isBackgroundPreview) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark
                ? AppColors.borderSubtleDark
                : AppColors.borderSubtleLight,
            width: 1,
          ),
        ),
        child: child,
      );
    }

    final matchColor = matchPct != null && matchPct! > 0
        ? MatchPercentageColors.colorFor(matchPct!)
        : null;
    const borderWidth = 2.5;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 1),
        gradient: matchColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  matchColor,
                  matchColor.withValues(alpha: 0.55),
                  AppColors.accentViolet.withValues(alpha: 0.85),
                ],
              )
            : AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(borderWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PhotoLayer extends StatelessWidget {
  const _PhotoLayer({
    required this.currentImage,
    required this.disableAnimations,
    required this.isBackgroundPreview,
  });

  final String? currentImage;
  final bool disableAnimations;
  final bool isBackgroundPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memCacheWidth = SwipeableCard.photoDecodeWidth(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: disableAnimations
              ? Duration.zero
              : AppAnimations.imageFadeIn,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: currentImage != null
              ? OptimizedImage(
                  key: ValueKey<String>(currentImage!),
                  imageUrl: currentImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  size: isBackgroundPreview
                      ? ImageSize.small
                      : ImageSize.large,
                  memoryCacheWidth: memCacheWidth,
                  showDownloadProgress: false,
                  placeholder: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: ColoredBox(
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

/// Scrim over the photo: a short soft band at the top so the photo indicator
/// and chips stay readable on bright photos, clear in the middle, and a
/// smooth ramp to near-black under the name and bio.
///
/// One static gradient inside the card's repaint boundary: it is painted
/// once, not while the card is dragged.
class _PhotoGradientOverlay extends StatelessWidget {
  const _PhotoGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.16, 0.44, 0.62, 0.80, 1.0],
          colors: [
            Colors.black.withValues(alpha: 0.36),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.30),
            Colors.black.withValues(alpha: 0.64),
            Colors.black.withValues(alpha: 0.90),
          ],
        ),
      ),
    );
  }
}

/// Chips at the top of the card: match percentage, "superliked you", and up
/// to [maxReasons] match reasons. More reasons collapse into a "+N" chip.
///
/// Each row shrinks its chips (ellipsis) instead of wrapping, so the block is
/// at most two rows whatever the text scale or card width.
class _CardChips extends StatelessWidget {
  const _CardChips({
    required this.matchPercentage,
    required this.isSuperliked,
    required this.reasons,
  });

  final int? matchPercentage;
  final bool isSuperliked;
  final List<MatchReason> reasons;

  static const int maxReasons = 2;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final shown = reasons.take(maxReasons).toList();
    final hidden = reasons.length - shown.length;
    final pct = matchPercentage;
    final hasFirstRow = pct != null || isSuperliked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasFirstRow)
          Row(
            children: [
              if (pct != null) Flexible(child: _MatchPercentageBadge(percentage: pct)),
              if (isSuperliked) ...[
                if (pct != null) const SizedBox(width: _gap),
                const _SuperlikedYouBadge(),
              ],
            ],
          ),
        if (shown.isNotEmpty) ...[
          if (hasFirstRow) const SizedBox(height: _gap),
          Row(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                Flexible(
                  child: _CardChip(
                    iconPath: matchReasonIconPath(shown[i].type),
                    label: shown[i].label,
                  ),
                ),
              ],
              if (hidden > 0) ...[
                const SizedBox(width: _gap),
                _CardChip(
                  label: '+$hidden',
                  semanticLabel: '$hidden more match reasons',
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// One pill on the card photo. All card chips share this shape, height and
/// type style; only the fill differs.
class _CardChip extends StatelessWidget {
  const _CardChip({
    required this.label,
    this.iconPath,
    this.fill,
    this.foreground = Colors.white,
    this.semanticLabel,
  });

  final String label;
  final String? iconPath;

  /// Defaults to a dark translucent fill that keeps white text above AA
  /// contrast on any photo.
  final Color? fill;
  final Color foreground;
  final String? semanticLabel;

  static const double minHeight = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Container(
        constraints: const BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: fill ?? Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          border: Border.all(
            color: Colors.white.withValues(alpha: fill == null ? 0.16 : 0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) ...[
              AppSvgIcon(assetPath: iconPath!, size: 14, color: foreground),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperlikedYouBadge extends StatelessWidget {
  const _SuperlikedYouBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Superliked you',
      child: Container(
        width: _CardChip.minHeight,
        height: _CardChip.minHeight,
        decoration: BoxDecoration(
          color: AppColors.warningYellow.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: const Center(
          child: AppSvgIcon(
            assetPath: AppIcons.star,
            size: 14,
            // Dark glyph: white on yellow does not reach 3:1.
            color: Colors.black87,
          ),
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
    final color = MatchPercentageColors.colorFor(percentage);
    // The band colours run from red to yellow to violet. White text fails
    // AA on the yellow and green bands, so pick the text colour per band.
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    return _CardChip(
      iconPath: AppIcons.getIconPath('magic-star'),
      label: 'Match $percentage%',
      fill: color.withValues(alpha: 0.94),
      foreground: foreground,
    );
  }
}

/// Thin segmented bar at the top of the card: one segment per photo, the
/// current one solid.
///
/// Segments follow the text direction, so the first photo is on the leading
/// side in RTL too, matching the tap zones.
class _PhotoSegmentIndicator extends StatelessWidget {
  const _PhotoSegmentIndicator({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  static const double height = 3;

  /// More photos than this and the segments get too short to read; the bar
  /// then shows a window around the current photo.
  static const int maxSegments = 9;

  @override
  Widget build(BuildContext context) {
    final visible = math.min(count, maxSegments);
    final first = count <= maxSegments
        ? 0
        : (activeIndex - maxSegments ~/ 2).clamp(0, count - maxSegments);

    return Semantics(
      label: 'Photo ${activeIndex + 1} of $count',
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < visible; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: first + i == activeIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(AppRadius.radiusRound),
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

class _BottomTextBlock extends StatelessWidget {
  const _BottomTextBlock({
    required this.name,
    required this.age,
    required this.city,
    required this.distance,
    required this.bio,
    required this.isOnline,
    required this.isVerified,
    required this.isPremium,
    required this.hideBioMore,
    required this.onBioMoreTap,
    required this.onProfileTap,
  });

  final String name;
  final int? age;
  final String? city;
  final double? distance;
  final String? bio;
  final bool isOnline;
  final bool isVerified;
  final bool isPremium;
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
              if (openProfile != null) ...[
                // Pull-up handle. It sits in the column, above the name, so
                // it can never land on top of the text.
                Center(
                  child: ExcludeSemantics(
                    child: Container(
                      width: AppSpacing.spacingXXL,
                      height: AppSpacing.spacingXS,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(
                          AppRadius.radiusRound,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacingSM),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: AppText(
                      age != null ? '$name, $age' : name,
                      maxLines: 1,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    Semantics(
                      label: 'Verified profile',
                      child: AppSvgIcon(
                        assetPath: AppIcons.getIconPath('verify'),
                        size: 20,
                        color: AppColors.feedbackInfo,
                      ),
                    ),
                  ],
                  if (isPremium) ...[
                    const SizedBox(width: 4),
                    Semantics(
                      label: 'Premium member',
                      child: AppSvgIcon(
                        assetPath: AppIcons.getIconPath('crown'),
                        size: 18,
                        color: AppColors.warningYellow,
                      ),
                    ),
                  ],
                  if (isOnline) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Online now',
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: kDiscoveryOnlineGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (city != null && city!.isNotEmpty || distance != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (city != null && city!.isNotEmpty) ...[
                      AppSvgIcon(
                        assetPath: AppIcons.getIconPath('location'),
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppText(
                          city!,
                          maxLines: 1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                    if (distance != null) ...[
                      if (city != null && city!.isNotEmpty)
                        const SizedBox(width: 8),
                      DistanceTag(
                        distance: distance!,
                        variant: DistanceTagVariant.onDark,
                      ),
                    ],
                  ],
                ),
              ],
              if (trimmedBio.isNotEmpty && !hideBioMore) ...[
                const SizedBox(height: 8),
                _BioPreview(
                  bio: trimmedBio,
                  showMore: openProfile != null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bio teaser: at most two lines, cut with an ellipsis at a word boundary by
/// the text layout. Long bios get a "more" label; the whole text block
/// already opens the profile on tap, so the label needs no recognizer.
class _BioPreview extends StatelessWidget {
  const _BioPreview({
    required this.bio,
    required this.showMore,
  });

  final String bio;
  final bool showMore;

  /// Bios longer than this rarely fit two lines on a phone card.
  static const int longBioLength = 70;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.82),
      height: 1.35,
    );
    final text = AppText(bio, maxLines: 2, style: style);
    if (!showMore || bio.length <= longBioLength) return text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        const SizedBox(width: AppSpacing.spacingSM),
        Text(
          'more',
          style: style?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    case 'same_city':
    case 'distance':
      return AppIcons.getIconPath('location');
    case 'job':
      return AppIcons.getIconPath('briefcase');
    case 'education':
      return AppIcons.getIconPath('teacher');
    case 'age':
    case 'preferred_gender':
    case 'gender':
    case 'your_type':
      return AppIcons.getIconPath('user-tag');
    case 'relationship':
    case 'relation_goal':
      return AppIcons.getIconPath('heart');
    default:
      return AppIcons.getIconPath('star');
  }
}
