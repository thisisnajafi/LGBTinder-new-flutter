// Widget: CardStackManager
// Card stack manager with horizontal swipe gestures
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/premium/premium_page.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/utils/app_haptics.dart';
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

enum _StampKind { like, nope, superlike }

/// Card stack manager widget
/// Manages a stack of swipeable cards for discovery screen
///
/// Dragging never rebuilds the cards. The drag offset lives in a
/// [ValueNotifier]; small [AnimatedBuilder]s turn it into transforms on
/// layers that are already painted (each card is a repaint boundary), and
/// the LIKE / NOPE / SUPER stamps fade and scale through
/// [FadeTransition] / [ScaleTransition]. No layout runs per frame.
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

  /// Icon of the primary / secondary empty-state buttons. Null keeps the
  /// empty state's defaults.
  final String? emptyActionIconPath;
  final String? emptySecondaryActionIconPath;
  final bool isSheetOpen;
  /// Resting position below header chrome; cards may paint above when swiping.
  final double contentTopInset;
  /// Keeps the default card position above the action row.
  final double contentBottomInset;
  /// Horizontal inset — use [AppSpacing.contentPadding] to match greeting card width.
  final double horizontalPadding;

  /// When false (Discover tab not selected), front-card photo carousel timers stop.
  final bool carouselEnabled;

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
    this.emptyActionIconPath,
    this.emptySecondaryActionIconPath,
    this.isSheetOpen = false,
    this.contentTopInset = 0,
    this.contentBottomInset = 0,
    this.horizontalPadding = PremiumPageHeader.horizontalPadding,
    this.carouselEnabled = true,
  });

  /// Stamp fade layers (tests read their opacity).
  @visibleForTesting
  static const Key likeStampKey = ValueKey('discover-stamp-like');
  @visibleForTesting
  static const Key nopeStampKey = ValueKey('discover-stamp-nope');
  @visibleForTesting
  static const Key superStampKey = ValueKey('discover-stamp-super');

  @override
  CardStackManagerState createState() => CardStackManagerState();
}

class CardStackManagerState extends ConsumerState<CardStackManager>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _exitingCardSnapshot;

  /// Offset of the front card from its resting place. Listened to by small
  /// transform builders, so a drag frame costs a matrix update and a
  /// re-composite — no `setState`, no card rebuild.
  final ValueNotifier<Offset> _drag = ValueNotifier<Offset>(Offset.zero);
  _SwipeLane _lane = _SwipeLane.undecided;
  bool _thresholdHapticFired = false;
  bool _animationsEnabled = true;

  /// 0 → 1 while the swiped card flies out.
  late final AnimationController _exitController;
  late final Animation<double> _exitCurve;
  Offset _exitFrom = Offset.zero;
  Offset _exitTo = Offset.zero;
  double _exitFromRotation = 0;
  double _exitToRotation = 0;

  /// Spring that carries the card back to rest after a drag that did not
  /// commit. 0 = where the finger let go, 1 = at rest (may overshoot).
  late final AnimationController _settleController;
  bool _settling = false;
  Offset _settleFrom = Offset.zero;

  /// How far the cards behind have moved up one place: 0 at rest, 1 when the
  /// front card is gone. Follows the drag, then the exit animation.
  late final AnimationController _deckProgress;

  /// Stamp visibility, 0..1. Set from the drag distance, or animated to 1
  /// when a button commits the swipe.
  late final AnimationController _likeStamp;
  late final AnimationController _nopeStamp;
  late final AnimationController _superStamp;

  /// Extra shadow while the card is held.
  late final AnimationController _lift;

  late AnimationController _revealController;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;
  late Animation<Offset> _revealSlide;
  Object? _lastTopCardId;
  int _prefetchGeneration = 0;
  bool _frontImagesReady = true;
  Timer? _frontPhotoTimer;
  final Map<int, GlobalKey> _cardKeys = <int, GlobalKey>{};

  static const double _laneLockDistance = 16;
  static const double _sheetOpenDistance = 72;
  static const double _horizontalArc = 0.10;
  static const double _flingVelocity = 850;

  /// Drag distance before a stamp starts to show, and the distance over
  /// which it reaches full strength.
  static const double _stampDeadZone = 12;
  static const double _stampRamp = 68;

  /// Slightly under-damped: the card returns quickly with a small, soft
  /// overshoot, like a card dropped back on a deck.
  static const SpringDescription _settleSpring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 30,
  );

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      duration: AppAnimations.cardExit,
      vsync: this,
    );
    _exitCurve = CurvedAnimation(
      parent: _exitController,
      curve: AppAnimations.curveDefault,
    );
    _settleController = AnimationController.unbounded(vsync: this)
      ..addListener(_onSettleTick);
    _deckProgress = AnimationController(vsync: this);
    _likeStamp = AnimationController(vsync: this);
    _nopeStamp = AnimationController(vsync: this);
    _superStamp = AnimationController(vsync: this);
    _lift = AnimationController(
      vsync: this,
      duration: AppAnimations.tapDuration,
    );
    _drag.addListener(_syncDragFeedback);

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsEnabled = AppAnimations.animationsEnabled(context);
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

    // Only the first photo of the front card holds the skeleton, and only
    // for a short while. Waiting for every photo of the stack kept the card
    // hidden for seconds on a slow connection (and for good on a dead one).
    final cards = widget.cards;
    final frontPhoto = DiscoveryImagePrefetch.frontPhotoUrl(cards);
    if (frontPhoto != null) {
      await _waitForFrontPhoto(frontPhoto);
    }

    if (!mounted || generation != _prefetchGeneration) return;
    _frontPhotoTimer?.cancel();

    if (blockUntilReady || !_frontImagesReady) {
      setState(() => _frontImagesReady = true);
      _playRevealAnimation();
    }

    // The other photos of the front card and the cards behind it load in
    // the background.
    unawaited(DiscoveryImagePrefetch.prefetchCardStack(cards));
  }

  /// Completes when [url] is on disk or after
  /// [DiscoveryImagePrefetch.frontPhotoWait], whichever comes first.
  Future<void> _waitForFrontPhoto(String url) {
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    // One timer at a time: a newer front card replaces the wait of the
    // previous one, whose result is dropped anyway.
    _frontPhotoTimer?.cancel();
    _frontPhotoTimer = Timer(DiscoveryImagePrefetch.frontPhotoWait, finish);
    unawaited(DiscoveryImagePrefetch.prefetchUrl(url).whenComplete(finish));
    return done.future;
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
    if (widget.isSheetOpen && !oldWidget.isSheetOpen) {
      // The sheet takes over: put the card back without a spring.
      _resetDrag();
    }
    if (oldTopId != newTopId && _exitingCardSnapshot == null) {
      // The front card changed under the finger (rewind, refresh, restore
      // after a failed swipe): the new card starts at rest.
      _resetDrag();
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
    _frontPhotoTimer?.cancel();
    _drag.removeListener(_syncDragFeedback);
    _drag.dispose();
    _exitController.removeStatusListener(_onExitStatus);
    _exitController.dispose();
    _settleController.dispose();
    _deckProgress.dispose();
    _likeStamp.dispose();
    _nopeStamp.dispose();
    _superStamp.dispose();
    _lift.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _onExitStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _exitController.removeStatusListener(_onExitStatus);
    if (!mounted) return;
    setState(() => _exitingCardSnapshot = null);
    // The card behind is now the front card: same place on screen, so the
    // deck can go back to its rest value without a visible jump.
    _deckProgress.value = 0;
    _clearStamps();
  }

  double get _swipeThreshold => MediaQuery.sizeOf(context).width * 0.22;

  /// Tilt of the front card for a horizontal offset: slight, and capped.
  double _rotationFor(double dx) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return 0;
    return (dx / width * 0.12).clamp(-0.15, 0.15);
  }

  static double _stampProgress(double distance) {
    return ((distance - _stampDeadZone) / _stampRamp).clamp(0.0, 1.0);
  }

  /// Keeps the stamps and the cards behind in step with the drag offset.
  ///
  /// Sets animation values only: listeners repaint or re-composite, nothing
  /// is rebuilt or laid out.
  void _syncDragFeedback() {
    if (_exitingCardSnapshot != null) return;
    final dx = _drag.value.dx;
    _likeStamp.value = _stampProgress(dx);
    _nopeStamp.value = _stampProgress(-dx);
    if (_animationsEnabled) {
      final threshold = _swipeThreshold;
      _deckProgress.value =
          threshold <= 0 ? 0 : (dx.abs() / threshold).clamp(0.0, 1.0);
    }
  }

  void _clearStamps() {
    _likeStamp.value = 0;
    _nopeStamp.value = 0;
    _superStamp.value = 0;
  }

  void _setLifted(bool lifted) {
    final target = lifted ? 1.0 : 0.0;
    if (_animationsEnabled) {
      _lift.animateTo(target);
    } else {
      _lift.value = target;
    }
  }

  /// Puts the front card back at rest at once (no spring).
  void _resetDrag() {
    _settling = false;
    _settleController.stop();
    _lane = _SwipeLane.undecided;
    _thresholdHapticFired = false;
    _lift.value = 0;
    _drag.value = Offset.zero;
  }

  void _onSettleTick() {
    if (!_settling) return;
    final remaining = 1 - _settleController.value;
    final dx = _settleFrom.dx * remaining;
    _drag.value = _lane == _SwipeLane.horizontal
        ? Offset(dx, -dx.abs() * _horizontalArc)
        : _settleFrom * remaining;
  }

  /// Springs the card back to rest, carrying the finger's [velocity] so the
  /// motion continues from the drag instead of restarting.
  void _settle(Offset velocity) {
    final from = _drag.value;
    if (from == Offset.zero || !_animationsEnabled) {
      _resetDrag();
      return;
    }
    _settling = false;
    _settleController.value = 0;
    _settleFrom = from;
    // Velocity along the way home, in "fractions of the distance per second".
    final towardsRest = from.distanceSquared < 1
        ? 0.0
        : (-(velocity.dx * from.dx + velocity.dy * from.dy) /
                from.distanceSquared)
            .clamp(-12.0, 12.0);
    _settling = true;
    _settleController
        .animateWith(SpringSimulation(_settleSpring, 0, 1, towardsRest))
        .then((_) {
      if (!mounted || !_settling) return;
      _resetDrag();
    });
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
    // Catching the card while it springs back keeps its lane.
    final caughtMidSettle = _settling && _drag.value != Offset.zero;
    _settling = false;
    _settleController.stop();
    if (!caughtMidSettle) _lane = _SwipeLane.undecided;
    _thresholdHapticFired = false;
    _setLifted(true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_exitingCardSnapshot != null || widget.isSheetOpen) return;
    final next = _constrainToLane(_drag.value + details.delta);
    final threshold = _swipeThreshold;
    final distance = next.dx.abs();
    if (_lane == _SwipeLane.horizontal) {
      if (distance >= threshold && !_thresholdHapticFired) {
        _thresholdHapticFired = true;
        AppHaptics.selection();
      } else if (distance < threshold * 0.8) {
        // Backed off: tick again if the finger crosses the line once more.
        _thresholdHapticFired = false;
      }
    }
    _drag.value = next;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_exitingCardSnapshot != null || widget.isSheetOpen) return;
    _setLifted(false);
    final velocity = details.velocity.pixelsPerSecond;
    final offset = _drag.value;

    if (_lane == _SwipeLane.vertical) {
      if (offset.dy < -_sheetOpenDistance || velocity.dy < -300) {
        AppHaptics.light();
        widget.onSheetOpenChanged?.call(true);
      }
      _settle(velocity);
      return;
    }

    if (offset.dx > _swipeThreshold || velocity.dx > _flingVelocity) {
      _handleAction('like');
      return;
    }
    if (offset.dx < -_swipeThreshold || velocity.dx < -_flingVelocity) {
      _handleAction('dislike');
      return;
    }

    _settle(velocity);
  }

  void _onPanCancel() {
    if (_exitingCardSnapshot != null) return;
    _setLifted(false);
    _settle(Offset.zero);
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
        primaryActionIconPath: widget.emptyActionIconPath,
        onPrimaryAction: widget.onEmptyAction ?? widget.onRefresh,
        secondaryActionLabel: widget.emptySecondaryActionLabel,
        secondaryActionIconPath: widget.emptySecondaryActionIconPath,
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
            // Small margin for the stacked cards peeking out below the top one.
            minimumVerticalMargin: AppSpacing.spacingMD,
          );

          final exiting = _exitingCardSnapshot;
          final exitingId = exiting?['id'];
          final remainingCards = [
            for (final card in widget.cards)
              if (card['id'] != exitingId) card,
          ];
          // While a card flies out, every card behind it is already one
          // place further forward in the list, so it starts one depth back
          // and [_deckProgress] carries it to its new place.
          final depthShift = exiting == null ? 0 : 1;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (remainingCards.length > 2)
                _buildStackCard(
                  remainingCards[2],
                  slot: 2,
                  restDepth: 2 + depthShift,
                  cardSize: cardSize,
                ),
              if (remainingCards.length > 1)
                _buildStackCard(
                  remainingCards[1],
                  slot: 1,
                  restDepth: 1 + depthShift,
                  cardSize: cardSize,
                ),
              if (remainingCards.isNotEmpty)
                exiting == null
                    ? _buildInteractiveTopCard(
                        remainingCards[0],
                        cardSize: cardSize,
                      )
                    : _buildStackCard(
                        remainingCards[0],
                        slot: 0,
                        restDepth: depthShift,
                        cardSize: cardSize,
                      ),
              if (exiting != null)
                _buildExitingCard(exiting, cardSize: cardSize),
            ],
          );
        },
      ),
    );
  }

  /// Deepest place a card is drawn at. Cards further back share it.
  static const int _maxDepth = 2;

  /// Perspective + scale/offset for a (fractional) stack depth: 0 is the
  /// front card, 1 and 2 the cards peeking out behind it.
  static Matrix4 _depthTransform(double depth) {
    final scale = 1.0 - (depth * 0.05);
    final tiltX = depth * 0.035;
    // -0.018 at depth 1, +0.018 at depth 2, straight at the front.
    final tiltZ = depth <= 1 ? -0.018 * depth : -0.018 + 0.036 * (depth - 1);
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0011)
      ..rotateX(tiltX)
      ..rotateZ(tiltZ)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(0, -depth * 8.0, 0, 1);
  }

  Widget _buildStackCard(
    Map<String, dynamic> cardData, {
    required int slot,
    required int restDepth,
    required Size cardSize,
  }) {
    final dim = Theme.of(context).scaffoldBackgroundColor;
    final scrimStrength = _deckProgress.drive(_DepthScrim(restDepth));

    return Positioned.fill(
      key: ValueKey<int>(cardData['id'] as int? ?? 0),
      child: IgnorePointer(
        // Only the front card takes input; a card on its way to the front
        // becomes interactive when the exit ends.
        child: AnimatedBuilder(
          animation: _deckProgress,
          builder: (context, child) {
            final depth = (restDepth - _deckProgress.value)
                .clamp(0.0, _maxDepth.toDouble());
            return Transform(
              alignment: Alignment.center,
              transform: _depthTransform(depth),
              child: child,
            );
          },
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: cardSize.width,
              height: cardSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: _buildCard(
                      cardData,
                      depth: slot,
                      isBackgroundPreview: slot > 0,
                    ),
                  ),
                  // Cards behind used to be faded with an Opacity widget,
                  // which blends the whole card through an offscreen buffer
                  // on every composited frame. A flat scrim in the page
                  // colour gives the same receding look for one rectangle.
                  FadeTransition(
                    opacity: scrimStrength,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: dim.withValues(alpha: _DepthScrim.maxAlpha),
                        borderRadius: BorderRadius.circular(
                          SwipeableCard.cardRadius,
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

    final sheetOpen = widget.isSheetOpen;

    return Positioned.fill(
      key: ValueKey<int>(cardData['id'] as int? ?? 0),
      child: FadeTransition(
        opacity: _revealOpacity,
        child: SlideTransition(
          position: _revealSlide,
          child: ScaleTransition(
            scale: _revealScale,
            child: Center(
              child: SizedBox(
                width: cardSize.width,
                height: cardSize.height,
                // The detector stays at the card's resting place and reads
                // the drag in screen axes, so the card's own tilt never
                // bends the gesture.
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onPanCancel: _onPanCancel,
                  child: AnimatedBuilder(
                    animation: _drag,
                    builder: (context, child) {
                      final offset = sheetOpen ? Offset.zero : _drag.value;
                      return Transform(
                        alignment: Alignment.center,
                        transform: _cardTransform(
                          offset,
                          _rotationFor(offset.dx),
                        ),
                        child: child,
                      );
                    },
                    // Built once per card, not per drag frame.
                    child: _buildCardLayer(
                      cardData,
                      showStamps: !sheetOpen,
                      showLift: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Translation by [offset], then a tilt of [rotation] around the centre.
  static Matrix4 _cardTransform(Offset offset, double rotation) {
    return Matrix4.translationValues(offset.dx, offset.dy, 0)
      ..rotateZ(rotation);
  }

  /// The front card with its stamps (and held-card shadow) on top.
  Widget _buildCardLayer(
    Map<String, dynamic> cardData, {
    required bool showStamps,
    required bool showLift,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        if (showLift)
          IgnorePointer(
            child: FadeTransition(
              opacity: _lift,
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      SwipeableCard.cardRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        RepaintBoundary(
          child: _buildCard(cardData, depth: 0),
        ),
        if (showStamps)
          Positioned.fill(
            child: IgnorePointer(
              child: _SwipeStamps(
                like: _likeStamp,
                nope: _nopeStamp,
                superlike: _superStamp,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExitingCard(
    Map<String, dynamic> cardData, {
    required Size cardSize,
  }) {
    return Positioned.fill(
      key: ValueKey<String>('exiting_${cardData['id']}'),
      child: IgnorePointer(
        child: Center(
          child: SizedBox(
            width: cardSize.width,
            height: cardSize.height,
            // Starts where the finger left the card (offset and tilt), so a
            // committed swipe carries on instead of snapping to the centre.
            child: AnimatedBuilder(
              animation: _exitCurve,
              builder: (context, child) {
                final t = _exitCurve.value;
                return Transform(
                  alignment: Alignment.center,
                  transform: _cardTransform(
                    Offset.lerp(_exitFrom, _exitTo, t)!,
                    lerpDouble(_exitFromRotation, _exitToRotation, t)!,
                  ),
                  child: child,
                );
              },
              child: _buildCardLayer(
                cardData,
                showStamps: true,
                showLift: false,
              ),
            ),
          ),
        ),
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
      carouselEnabled: widget.carouselEnabled,
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

  /// Starts the fly-out of the front card towards [to].
  ///
  /// Returns false when nothing was started (no card, an exit already
  /// running, or Reduce Motion is on — the card then just swaps).
  bool _startExit({
    required Offset to,
    required double toRotation,
    required _StampKind stamp,
  }) {
    if (!mounted || widget.cards.isEmpty || _exitingCardSnapshot != null) {
      return false;
    }
    if (!_animationsEnabled) {
      _resetDrag();
      _clearStamps();
      return false;
    }

    final exitingCard = Map<String, dynamic>.from(widget.cards[0]);
    _settling = false;
    _settleController.stop();
    _exitFrom = _drag.value;
    _exitFromRotation = _rotationFor(_exitFrom.dx);
    _exitTo = to;
    _exitToRotation = toRotation;

    setState(() => _exitingCardSnapshot = exitingCard);
    // From here the drag listener is muted (an exit is running), so the
    // next front card can be put at rest without touching the stamps.
    _lane = _SwipeLane.undecided;
    _thresholdHapticFired = false;
    _lift.value = 0;
    _drag.value = Offset.zero;

    // A button tap has no drag behind it: pop the stamp in. After a drag it
    // is already (nearly) at full strength and this is a no-op.
    const stampIn = Duration(milliseconds: 110);
    _likeStamp.animateTo(
      stamp == _StampKind.like ? 1 : 0,
      duration: stampIn,
      curve: Curves.easeOut,
    );
    _nopeStamp.animateTo(
      stamp == _StampKind.nope ? 1 : 0,
      duration: stampIn,
      curve: Curves.easeOut,
    );
    _superStamp.animateTo(
      stamp == _StampKind.superlike ? 1 : 0,
      duration: stampIn,
      curve: Curves.easeOut,
    );
    _deckProgress.animateTo(
      1,
      duration: AppAnimations.cardExit,
      curve: AppAnimations.curveDefault,
    );

    _exitController
      ..reset()
      ..addStatusListener(_onExitStatus)
      ..forward();
    return true;
  }

  Offset _horizontalExitTarget({required bool toRight}) {
    final width = MediaQuery.sizeOf(context).width;
    return Offset(
      (toRight ? 1 : -1) * width * 1.25,
      _drag.value.dy - width * 0.06,
    );
  }

  /// Plays the SUPER stamp + upward exit after the message sheet succeeds.
  void beginSuperlikeExit() {
    _startExit(
      to: Offset(0, -MediaQuery.sizeOf(context).height * 1.1),
      toRotation: 0,
      stamp: _StampKind.superlike,
    );
  }

  /// Plays the LIKE / NOPE stamp and fly-out for a swipe committed outside
  /// the gesture (action bar, profile sheet). Does not report the swipe:
  /// the caller records it.
  ///
  /// [action] is `like` or `dislike`; anything else is ignored.
  void beginSwipeExit(String action) {
    if (action != 'like' && action != 'dislike') return;
    final isLike = action == 'like';
    _startExit(
      to: _horizontalExitTarget(toRight: isLike),
      toRotation: isLike ? 0.22 : -0.22,
      stamp: isLike ? _StampKind.like : _StampKind.nope,
    );
  }

  void _handleAction(String action) {
    if (widget.cards.isEmpty || _exitingCardSnapshot != null) return;

    if (widget.isSheetOpen) {
      widget.onSheetOpenChanged?.call(false);
    }

    final userId = widget.cards[0]['id'] as int? ?? 0;
    if (action == 'superlike') {
      widget.onSwipe?.call(userId, 'superlike');
      return;
    }

    final isLike = action == 'like';
    _startExit(
      to: _horizontalExitTarget(toRight: isLike),
      toRotation: isLike ? 0.22 : -0.22,
      stamp: isLike ? _StampKind.like : _StampKind.nope,
    );
    widget.onSwipe?.call(userId, action);
  }
}

/// Strength of the dimming scrim on a card behind the front card, as the
/// deck moves forward: none at the front, [maxAlpha] at the deepest place.
class _DepthScrim extends Animatable<double> {
  const _DepthScrim(this.restDepth);

  final int restDepth;

  /// Scrim alpha at depth 2. Matches the old 0.86 / 0.72 card opacities.
  static const double maxAlpha = 0.28;

  @override
  double transform(double t) {
    final depth = (restDepth - t).clamp(0.0, 2.0);
    return depth / 2;
  }
}

/// LIKE / NOPE / SUPER stamps on the front card.
///
/// Each stamp fades and grows with its animation (drag progress, or a short
/// pop when a button commits the swipe). The stamps are built once; only
/// opacity and scale change per frame.
class _SwipeStamps extends StatelessWidget {
  const _SwipeStamps({
    required this.like,
    required this.nope,
    required this.superlike,
  });

  final Animation<double> like;
  final Animation<double> nope;
  final Animation<double> superlike;

  static final Animatable<double> _grow = Tween<double>(begin: 0.72, end: 1);

  // Clear of the photo indicator and chips at the top of the card.
  static const double _top = 64;
  static const double _side = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Swipe directions are physical (right = like), so the stamps sit on
    // physical sides too, also in RTL.
    return Stack(
      children: [
        Positioned(
          top: _top,
          left: _side,
          child: _stamp(
            theme,
            key: CardStackManager.likeStampKey,
            animation: like,
            text: 'LIKE',
            color: AppColors.feedbackSuccess,
            angle: -0.18,
          ),
        ),
        Positioned(
          top: _top,
          right: _side,
          child: _stamp(
            theme,
            key: CardStackManager.nopeStampKey,
            animation: nope,
            text: 'NOPE',
            color: theme.colorScheme.error,
            angle: 0.18,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: _top),
            child: _stamp(
              theme,
              key: CardStackManager.superStampKey,
              animation: superlike,
              text: 'SUPER',
              color: theme.colorScheme.primary,
              angle: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stamp(
    ThemeData theme, {
    required Key key,
    required Animation<double> animation,
    required String text,
    required Color color,
    required double angle,
  }) {
    return ExcludeSemantics(
      child: FadeTransition(
        key: key,
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(_grow),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingMD,
                vertical: AppSpacing.spacingXS,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                // Dark backing keeps the coloured word readable on any
                // photo, bright or dark.
                color: Colors.black.withValues(alpha: 0.38),
                border: Border.all(color: color, width: 3),
              ),
              child: Text(
                text,
                // Decorative and already large: do not grow with text scale.
                textScaler: TextScaler.noScaling,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
