// Widget: CardStackManager
// Card stack manager with horizontal swipe gestures
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/premium/premium_page.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/constants/animation_constants.dart';
import '../../shared/models/match_reason.dart';
import 'swipeable_card.dart';
import '../../features/discover/widgets/discover_empty_state.dart';
import '../../features/discover/utils/discovery_image_prefetch.dart';
import '../../widgets/loading/skeleton_loader.dart';
import '../../core/widgets/loading_indicator.dart';

/// True when [cardId] was already painted in the visible deck, so promoting
/// it to the front must not rebuild the photo as a fresh network load.
bool discoverCardWasVisibleInStack(
  Object? cardId,
  List<Map<String, dynamic>> previousCards, {
  int visibleCount = 3,
}) {
  if (cardId == null) return false;
  final limit = previousCards.length < visibleCount
      ? previousCards.length
      : visibleCount;
  for (var i = 0; i < limit; i++) {
    if (previousCards[i]['id'] == cardId) return true;
  }
  return false;
}

enum _SwipeLane { undecided, horizontal, vertical }

enum _StampKind { none, like, nope, superlike }

/// Card stack manager widget
/// Manages a stack of swipeable cards for discovery screen
class CardStackManager extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> cards;
  final Function(int userId, String action)? onSwipe;
  final Function(int userId)? onViewProfile;
  final ValueChanged<bool>? onSheetOpenChanged;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? emptySecondaryActionLabel;
  final VoidCallback? onEmptySecondaryAction;
  final String? emptyTertiaryActionLabel;
  final VoidCallback? onEmptyTertiaryAction;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? emptyIconPath;
  final bool isSheetOpen;
  /// Resting position below header chrome; cards may paint above when swiping.
  final double contentTopInset;
  /// Keeps the default card position above the action row.
  final double contentBottomInset;
  /// Horizontal inset — use [AppSpacing.contentPadding] to match greeting card width.
  final double horizontalPadding;

  const CardStackManager({
    super.key,
    required this.cards,
    this.onSwipe,
    this.onViewProfile,
    this.onSheetOpenChanged,
    this.isLoading = false,
    this.onRefresh,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.emptySecondaryActionLabel,
    this.onEmptySecondaryAction,
    this.emptyTertiaryActionLabel,
    this.onEmptyTertiaryAction,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIconPath,
    this.isSheetOpen = false,
    this.contentTopInset = 0,
    this.contentBottomInset = 0,
    this.horizontalPadding = PremiumPageHeader.horizontalPadding,
  });

  @override
  CardStackManagerState createState() => CardStackManagerState();
}

class CardStackManagerState extends ConsumerState<CardStackManager>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _exitingCardSnapshot;
  Offset _dragOffset = Offset.zero;
  _SwipeLane _lane = _SwipeLane.undecided;
  bool _thresholdHapticFired = false;
  late AnimationController _exitController;
  late Animation<Offset> _exitSlide;
  late Animation<double> _exitFade;
  late AnimationController _revealController;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;
  late Animation<Offset> _revealSlide;
  Object? _lastTopCardId;
  int _prefetchGeneration = 0;
  bool _frontImagesReady = true;
  final Map<int, GlobalKey> _cardKeys = <int, GlobalKey>{};
  _StampKind _exitStamp = _StampKind.none;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      duration: AppAnimations.cardExit,
      vsync: this,
    );
    _exitSlide = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: AppAnimations.curveDefault,
      ),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: AppAnimations.curveDefault,
      ),
    );
    _revealController = AnimationController(
      duration: AppAnimations.cardReveal,
      vsync: this,
    );
    final revealCurve = CurvedAnimation(
      parent: _revealController,
      curve: AppAnimations.curveDefault,
    );
    _revealScale = Tween<double>(begin: 0.94, end: 1).animate(revealCurve);
    _revealOpacity = Tween<double>(begin: 0, end: 1).animate(revealCurve);
    _revealSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(revealCurve);
    if (widget.cards.isNotEmpty) {
      _lastTopCardId = widget.cards.first['id'];
      _frontImagesReady = false;
      _revealController.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_prepareFrontCards(blockUntilReady: true));
        }
      });
    }
  }

  Key _keyForCard(int userId) {
    return _cardKeys.putIfAbsent(userId, GlobalKey.new);
  }

  void _pruneCardKeys() {
    final live = <int>{};
    for (final card in widget.cards.take(4)) {
      final id = card['id'];
      if (id is int) live.add(id);
    }
    final exitingId = _exitingCardSnapshot?['id'];
    if (exitingId is int) live.add(exitingId);
    _cardKeys.removeWhere((id, _) => !live.contains(id));
  }

  Future<void> _prepareFrontCards({required bool blockUntilReady}) async {
    if (widget.cards.isEmpty || widget.isLoading) return;

    final generation = ++_prefetchGeneration;
    if (blockUntilReady && mounted) {
      setState(() {
        _frontImagesReady = false;
      });
      _revealController.value = 0;
    }

    await DiscoveryImagePrefetch.prefetchCardStack(widget.cards);

    if (!mounted || generation != _prefetchGeneration) return;

    if (blockUntilReady || !_frontImagesReady) {
      setState(() => _frontImagesReady = true);
      _playRevealAnimation();
    }
  }

  void _playRevealAnimation() {
    if (!mounted) return;
    if (!AppAnimations.animationsEnabled(context)) {
      _revealController.value = 1;
      return;
    }
    _revealController.forward(from: 0);
  }

  @override
  void didUpdateWidget(CardStackManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTopId =
        oldWidget.cards.isNotEmpty ? oldWidget.cards.first['id'] : null;
    final newTopId = widget.cards.isNotEmpty ? widget.cards.first['id'] : null;
    if (oldTopId != newTopId && widget.isSheetOpen) {
      widget.onSheetOpenChanged?.call(false);
    }
    if (oldWidget.cards.isEmpty && widget.cards.isNotEmpty) {
      _lastTopCardId = widget.cards.first['id'];
      unawaited(_prepareFrontCards(blockUntilReady: true));
    } else if (newTopId != null && newTopId != _lastTopCardId) {
      final alreadyVisible = discoverCardWasVisibleInStack(
        newTopId,
        oldWidget.cards,
      );
      _lastTopCardId = newTopId;
      unawaited(_prepareFrontCards(blockUntilReady: !alreadyVisible));
    }
    _pruneCardKeys();
    if (widget.cards.isEmpty && _exitingCardSnapshot == null) {
      _resetDrag();
      _lastTopCardId = null;
      _frontImagesReady = true;
    }
  }

  @override
  void dispose() {
    _exitController.removeStatusListener(_onExitStatus);
    _exitController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _onExitStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _exitController.removeStatusListener(_onExitStatus);
    if (mounted) {
      setState(() {
        _exitingCardSnapshot = null;
        _exitStamp = _StampKind.none;
        _dragOffset = Offset.zero;
      });
    }
  }

  double get _swipeThreshold => MediaQuery.sizeOf(context).width * 0.22;
  static const double _laneLockDistance = 16;
  static const double _sheetOpenDistance = 72;
  static const double _horizontalArc = 0.10;

  void _resetDrag() {
    _dragOffset = Offset.zero;
    _lane = _SwipeLane.undecided;
    _thresholdHapticFired = false;
  }

  Offset _constrainToLane(Offset next) {
    if (_lane == _SwipeLane.undecided && next.distance >= _laneLockDistance) {
      final goingUp =
          next.dy < 0 && next.dy.abs() > next.dx.abs() * 1.2;
      _lane = goingUp ? _SwipeLane.vertical : _SwipeLane.horizontal;
    }

    switch (_lane) {
      case _SwipeLane.undecided:
        return Offset(next.dx, next.dy * 0.25);
      case _SwipeLane.horizontal:
        return Offset(next.dx, -next.dx.abs() * _horizontalArc);
      case _SwipeLane.vertical:
        return Offset(0, math.min(next.dy, 0));
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_exitingCardSnapshot != null || widget.isSheetOpen) return;
    _lane = _SwipeLane.undecided;
    _thresholdHapticFired = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_exitingCardSnapshot != null || widget.isSheetOpen) return;
    final next = _constrainToLane(_dragOffset + details.delta);
    final crossedLike = next.dx.abs() >= _swipeThreshold;
    if (crossedLike && !_thresholdHapticFired && _lane == _SwipeLane.horizontal) {
      _thresholdHapticFired = true;
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _dragOffset = next);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_exitingCardSnapshot != null || widget.isSheetOpen) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    if (_lane == _SwipeLane.vertical) {
      if (_dragOffset.dy < -_sheetOpenDistance || vy < -300) {
        unawaited(HapticFeedback.lightImpact());
        widget.onSheetOpenChanged?.call(true);
      }
      setState(_resetDrag);
      return;
    }

    if (_dragOffset.dx > _swipeThreshold || vx > 850) {
      _handleAction('like');
      return;
    }
    if (_dragOffset.dx < -_swipeThreshold || vx < -850) {
      _handleAction('dislike');
      return;
    }

    setState(_resetDrag);
  }

  void _onPanCancel() {
    if (_exitingCardSnapshot != null) return;
    setState(_resetDrag);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const LoadingIndicator(message: 'Loading profiles...');
    }

    if (widget.cards.isEmpty && _exitingCardSnapshot == null) {
      final hasCustomEmpty = widget.emptyTitle != null ||
          widget.emptySubtitle != null ||
          widget.emptyIconPath != null ||
          widget.emptyActionLabel != null ||
          widget.onEmptyAction != null ||
          widget.onRefresh != null ||
          widget.emptySecondaryActionLabel != null ||
          widget.onEmptySecondaryAction != null ||
          widget.emptyTertiaryActionLabel != null ||
          widget.onEmptyTertiaryAction != null;
      if (!hasCustomEmpty) {
        return const DiscoverEmptyState();
      }
      return DiscoverEmptyState(
        title: widget.emptyTitle ?? "You've seen everyone nearby",
        subtitle: widget.emptySubtitle ??
            'Check back soon or expand your filters to see more people',
        iconPath: widget.emptyIconPath,
        primaryActionLabel: widget.emptyActionLabel ?? 'Adjust filters',
        onPrimaryAction: widget.onEmptyAction ?? widget.onRefresh,
        secondaryActionLabel: widget.emptySecondaryActionLabel,
        onSecondaryAction: widget.onEmptySecondaryAction,
        tertiaryActionLabel: widget.emptyTertiaryActionLabel,
        onTertiaryAction: widget.onEmptyTertiaryAction,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.horizontalPadding,
        widget.contentTopInset,
        widget.horizontalPadding,
        widget.contentBottomInset,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardSize = SwipeableCard.fitSize(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            minimumVerticalMargin: AppSpacing.spacingLG * 2,
          );

          final exitingId = _exitingCardSnapshot?['id'];
          final remainingCards = [
            for (final card in widget.cards)
              if (card['id'] != exitingId) card,
          ];

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (remainingCards.length > 2)
                _buildStackCard(
                  remainingCards[2],
                  depth: 2,
                  cardSize: cardSize,
                ),
              if (remainingCards.length > 1)
                _buildStackCard(
                  remainingCards[1],
                  depth: 1,
                  cardSize: cardSize,
                ),
              if (remainingCards.isNotEmpty)
                _exitingCardSnapshot == null
                    ? _buildInteractiveTopCard(
                        remainingCards[0],
                        cardSize: cardSize,
                      )
                    : _buildStackCard(
                        remainingCards[0],
                        depth: 0,
                        cardSize: cardSize,
                      ),
              if (_exitingCardSnapshot != null)
                _buildExitingCard(
                  _exitingCardSnapshot!,
                  cardSize: cardSize,
                ),
            ],
          );
        },
      ),
    );
  }

  /// Perspective + scale/offset per stack depth for a layered 3D deck.
  Widget _applyStackDepth({
    required Widget child,
    required int depth,
  }) {
    final scale = 1.0 - (depth * 0.05);
    final tiltX = depth * 0.035;
    final tiltZ = depth == 1 ? -0.018 : depth == 2 ? 0.018 : 0.0;
    final opacity = (1.0 - depth * 0.14).clamp(0.72, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(tiltX)
          ..rotateZ(tiltZ)
          ..scaleByDouble(scale, scale, 1, 1),
        child: Transform.translate(
          offset: Offset(0, -depth * 8.0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStackCard(
    Map<String, dynamic> cardData, {
    required int depth,
    required Size cardSize,
  }) {
    return Positioned.fill(
      key: ValueKey<int>(cardData['id'] as int? ?? 0),
      child: _applyStackDepth(
        depth: depth,
            child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: cardSize.width,
            height: cardSize.height,
            child: RepaintBoundary(
              child: _buildCard(
              cardData,
              depth: depth,
              isBackgroundPreview: depth > 0,
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTopCard(
    Map<String, dynamic> cardData, {
    required Size cardSize,
  }) {
    if (!_frontImagesReady) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Positioned.fill(
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: cardSize.width,
            height: cardSize.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
              child: Column(
                children: [
                  Expanded(
                    child: SkeletonLoader(
                      width: double.infinity,
                      height: double.infinity,
                      highlightColorOverride: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppColors.lgbtGradient[4].withValues(alpha: 0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(
                          width: 140,
                          height: 18,
                        ),
                        const SizedBox(height: AppSpacing.spacingSM),
                        SkeletonLoader(
                          width: 90,
                          height: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final rotation = widget.isSheetOpen
        ? 0.0
        : (_dragOffset.dx / width * 0.12).clamp(-0.15, 0.15);

    final isDragging = !widget.isSheetOpen && _dragOffset != Offset.zero;

    return Positioned.fill(
      key: ValueKey<int>(cardData['id'] as int? ?? 0),
      child: FadeTransition(
        opacity: _revealOpacity,
        child: SlideTransition(
          position: _revealSlide,
          child: ScaleTransition(
            scale: _revealScale,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: widget.isSheetOpen ? Offset.zero : _dragOffset,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0011)
                      ..rotateZ(rotation),
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onPanCancel: _onPanCancel,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: isDragging
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withValues(alpha: 0.22),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: SizedBox(
                          width: cardSize.width,
                          height: cardSize.height,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              RepaintBoundary(
                                child: _buildCard(cardData, depth: 0),
                              ),
                              if (!widget.isSheetOpen) _buildSwipeOverlay(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitingCard(
    Map<String, dynamic> cardData, {
    required Size cardSize,
  }) {
    return Positioned.fill(
      key: ValueKey<String>('exiting_${cardData['id']}'),
      child: SlideTransition(
        position: _exitSlide,
        child: FadeTransition(
          opacity: _exitFade,
          child: Align(
            alignment: Alignment.center,
              child: SizedBox(
                width: cardSize.width,
                height: cardSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildCard(cardData, depth: 0),
                    _buildSwipeOverlay(forExit: true),
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeOverlay({bool forExit = false}) {
    final theme = Theme.of(context);
    final committed = forExit || _exitStamp != _StampKind.none;
    final likeOpacity = committed
        ? (_exitStamp == _StampKind.like ? 1.0 : 0.0)
        : (_lane == _SwipeLane.horizontal
            ? (_dragOffset.dx / 80.0).clamp(0.0, 1.0)
            : 0.0);
    final nopeOpacity = committed
        ? (_exitStamp == _StampKind.nope ? 1.0 : 0.0)
        : (_lane == _SwipeLane.horizontal
            ? ((-_dragOffset.dx) / 80.0).clamp(0.0, 1.0)
            : 0.0);
    final superOpacity =
        committed && _exitStamp == _StampKind.superlike ? 1.0 : 0.0;

    Widget stamp({
      required String text,
      required Color borderColor,
      required Color textColor,
      required double opacity,
      required double angle,
    }) {
      if (opacity <= 0) return const SizedBox.shrink();
      return Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingSM,
              vertical: AppSpacing.spacingXS,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusXS),
              color: borderColor.withValues(alpha: 0.16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Text(
              text,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 20,
            child: stamp(
              text: 'LIKE',
              borderColor: AppColors.feedbackSuccess,
              textColor: AppColors.feedbackSuccess,
              opacity: likeOpacity,
              angle: -0.18,
            ),
          ),
          Positioned(
            top: 24,
            right: 20,
            child: stamp(
              text: 'NOPE',
              borderColor: theme.colorScheme.error,
              textColor: theme.colorScheme.error,
              opacity: nopeOpacity,
              angle: 0.18,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: stamp(
                text: 'SUPER',
                borderColor: theme.colorScheme.primary,
                textColor: theme.colorScheme.primary,
                opacity: superOpacity,
                angle: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    Map<String, dynamic> cardData, {
    required int depth,
    bool isBackgroundPreview = false,
  }) {
    final userId = cardData['id'] as int? ?? 0;
    final matchReasons = (cardData['match_reasons'] as List?)
            ?.map((e) => e is MatchReason
                ? e
                : MatchReason.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const <MatchReason>[];

    return SwipeableCard(
      key: _keyForCard(userId),
      userId: userId,
      name: cardData['name']?.toString() ?? 'User',
      age: cardData['age'] as int?,
      city: cardData['city']?.toString() ?? _cityFromLocation(cardData['location']),
      country: cardData['country']?.toString(),
      avatarUrl: cardData['avatar_url']?.toString(),
      imageUrls: _imageUrlsFromCard(cardData),
      bio: cardData['bio']?.toString(),
      isVerified: cardData['is_verified'] == true,
      isPremium: cardData['is_premium'] == true,
      isSuperliked: cardData['is_superliked'] == true,
      isOnline: cardData['is_online'] == true,
      distance: (cardData['distance'] as num?)?.toDouble(),
      matchPercentage: (cardData['match_percentage'] as num?)?.toInt() ??
          (cardData['compatibility_score'] as num?)?.toInt(),
      matchReasons: matchReasons,
      isExpanded: depth == 0 && widget.isSheetOpen,
      isBackgroundPreview: isBackgroundPreview,
      onBioMoreTap: depth == 0 && !isBackgroundPreview
          ? () => widget.onSheetOpenChanged?.call(true)
          : null,
      onProfileTap: depth == 0 && !isBackgroundPreview
          ? () => widget.onSheetOpenChanged?.call(true)
          : null,
    );
  }

  List<String>? _imageUrlsFromCard(Map<String, dynamic> cardData) {
    final seen = <String>{};
    final list = <String>[];
    final raw = cardData['image_urls'];
    if (raw is List) {
      for (final entry in raw) {
        final url = entry?.toString().trim() ?? '';
        if (url.isNotEmpty && seen.add(url)) {
          list.add(url);
        }
      }
    }
    final avatar = cardData['avatar_url']?.toString().trim();
    if (avatar != null && avatar.isNotEmpty) {
      if (seen.add(avatar)) {
        list.insert(0, avatar);
      } else if (list.isNotEmpty && list.first != avatar) {
        list.remove(avatar);
        list.insert(0, avatar);
      }
    }
    return list.isEmpty ? null : list;
  }

  String? _cityFromLocation(dynamic location) {
    if (location == null) return null;
    final text = location.toString();
    if (text.isEmpty) return null;
    return text.split(',').first.trim();
  }

  /// Plays the SUPER stamp + upward exit after the message sheet succeeds.
  void beginSuperlikeExit() {
    if (!mounted || widget.cards.isEmpty || _exitingCardSnapshot != null) {
      return;
    }

    final exitingCard = Map<String, dynamic>.from(widget.cards[0]);
    _exitStamp = _StampKind.superlike;

    if (!AppAnimations.animationsEnabled(context)) {
      setState(() {
        _exitingCardSnapshot = exitingCard;
        _resetDrag();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _exitingCardSnapshot = null;
          _exitStamp = _StampKind.none;
        });
      });
      return;
    }

    _exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.2),
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: AppAnimations.curveDefault,
      ),
    );

    setState(() {
      _exitingCardSnapshot = exitingCard;
      _resetDrag();
    });

    _exitController
      ..reset()
      ..addStatusListener(_onExitStatus)
      ..forward();
  }

  void _handleAction(String action) {
    if (widget.cards.isEmpty || _exitingCardSnapshot != null) return;

    if (widget.isSheetOpen) {
      widget.onSheetOpenChanged?.call(false);
    }

    if (action == 'superlike') {
      final userId = widget.cards[0]['id'] as int? ?? 0;
      widget.onSwipe?.call(userId, 'superlike');
      return;
    }

    final exitingCard = Map<String, dynamic>.from(widget.cards[0]);
    final userId = exitingCard['id'] as int? ?? 0;
    final isLike = action == 'like';
    final direction = isLike ? const Offset(1.2, 0) : const Offset(-1.2, 0);
    _exitStamp = isLike ? _StampKind.like : _StampKind.nope;

    if (!AppAnimations.animationsEnabled(context)) {
      widget.onSwipe?.call(userId, action);
      _exitStamp = _StampKind.none;
      return;
    }

    _exitSlide = Tween<Offset>(begin: Offset.zero, end: direction).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: AppAnimations.curveDefault,
      ),
    );

    setState(() {
      _exitingCardSnapshot = exitingCard;
      _resetDrag();
    });

    widget.onSwipe?.call(userId, action);

    _exitController
      ..reset()
      ..addStatusListener(_onExitStatus)
      ..forward();
  }
}
