// Widget: CardStackManager
// Card stack manager with horizontal swipe gestures
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/constants/animation_constants.dart';
import '../../shared/models/match_reason.dart';
import 'swipeable_card.dart';
import '../../features/discover/widgets/discover_empty_state.dart';
import '../../features/discover/utils/discovery_image_prefetch.dart';
import '../../core/widgets/loading_indicator.dart';

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
  final bool isSheetOpen;
  /// Resting position below header chrome; cards may paint above when swiping.
  final double contentTopInset;
  /// Keeps the default card position above the action row.
  final double contentBottomInset;

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
    this.isSheetOpen = false,
    this.contentTopInset = 0,
    this.contentBottomInset = 0,
  });

  @override
  ConsumerState<CardStackManager> createState() => _CardStackManagerState();
}

class _CardStackManagerState extends ConsumerState<CardStackManager>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _exitingCardSnapshot;
  Offset _dragOffset = Offset.zero;
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
        if (mounted) unawaited(_prepareFrontCards());
      });
    }
  }

  Future<void> _prepareFrontCards() async {
    if (widget.cards.isEmpty || widget.isLoading) return;

    final generation = ++_prefetchGeneration;
    if (mounted) {
      setState(() {
        _frontImagesReady = false;
      });
      _revealController.value = 0;
    }

    await DiscoveryImagePrefetch.prefetchCardStack(widget.cards);

    if (!mounted || generation != _prefetchGeneration) return;

    setState(() => _frontImagesReady = true);
    _playRevealAnimation();
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
      unawaited(_prepareFrontCards());
    }
    if (newTopId != null && newTopId != _lastTopCardId) {
      _lastTopCardId = newTopId;
      unawaited(_prepareFrontCards());
    }
    if (widget.cards.isEmpty && _exitingCardSnapshot == null) {
      _dragOffset = Offset.zero;
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
        _dragOffset = Offset.zero;
      });
    }
  }

  double get _swipeThreshold => MediaQuery.sizeOf(context).width * 0.22;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_exitingCardSnapshot != null || widget.isSheetOpen) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_exitingCardSnapshot != null || widget.isSheetOpen) return;
    final isPrimarilyVertical =
        _dragOffset.dy.abs() > (_dragOffset.dx.abs() * 1.35);
    if (isPrimarilyVertical) {
      if (_dragOffset.dy < -100 || details.velocity.pixelsPerSecond.dy < -300) {
        widget.onSheetOpenChanged?.call(true);
        setState(() => _dragOffset = Offset.zero);
        return;
      }
    }
    if (_dragOffset.dx > _swipeThreshold) {
      _handleAction('like');
      return;
    }
    if (_dragOffset.dx < -_swipeThreshold) {
      _handleAction('dislike');
      return;
    }
    setState(() => _dragOffset = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const LoadingIndicator(message: 'Loading profiles...');
    }

    if (widget.cards.isEmpty && _exitingCardSnapshot == null) {
      return DiscoverEmptyState(
        onAdjustFilters: widget.onEmptyAction ?? widget.onRefresh,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.spacingLG,
        widget.contentTopInset,
        AppSpacing.spacingLG,
        widget.contentBottomInset,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (widget.cards.length > 2)
            _buildStackCard(widget.cards[2], depth: 2),
          if (widget.cards.length > 1)
            _buildStackCard(widget.cards[1], depth: 1),
          if (widget.cards.isNotEmpty)
            _exitingCardSnapshot == null
                ? _buildInteractiveTopCard(widget.cards[0])
                : _buildStackCard(widget.cards[0], depth: 0),
          if (_exitingCardSnapshot != null)
            _buildExitingCard(_exitingCardSnapshot!),
        ],
      ),
    );
  }

  /// Perspective + scale/offset per stack depth for a layered 3D deck.
  Widget _applyStackDepth({
    required Widget child,
    required int depth,
  }) {
    final scale = 1.0 - (depth * 0.05);
    final verticalOffset = depth * 12.0;
    final tiltX = depth * 0.035;
    final tiltZ = depth == 1 ? -0.018 : depth == 2 ? 0.018 : 0.0;
    final opacity = (1.0 - depth * 0.14).clamp(0.72, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(tiltX)
          ..rotateZ(tiltZ)
          ..scale(scale, scale, 1),
        child: Padding(
          padding: EdgeInsets.only(top: verticalOffset),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStackCard(Map<String, dynamic> cardData, {required int depth}) {
    return Positioned.fill(
      child: _applyStackDepth(
        depth: depth,
        child: Align(
          alignment: Alignment.topCenter,
          child: AspectRatio(
            aspectRatio: SwipeableCard.cardAspectRatio,
            child: _buildCard(
              cardData,
              depth: depth,
              isBackgroundPreview: depth > 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTopCard(Map<String, dynamic> cardData) {
    if (!_frontImagesReady) {
      return Positioned.fill(
        child: Align(
          alignment: Alignment.topCenter,
          child: AspectRatio(
            aspectRatio: SwipeableCard.cardAspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: LoadingIndicator(size: 36),
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
      child: FadeTransition(
        opacity: _revealOpacity,
        child: SlideTransition(
          position: _revealSlide,
          child: ScaleTransition(
            scale: _revealScale,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Transform.translate(
                  offset: widget.isSheetOpen ? Offset.zero : _dragOffset,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0011)
                      ..rotateZ(rotation),
                    child: GestureDetector(
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: isDragging
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildCard(cardData, depth: 0),
                            if (!widget.isSheetOpen) _buildSwipeOverlay(),
                          ],
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

  Widget _buildExitingCard(Map<String, dynamic> cardData) {
    return Positioned.fill(
      child: SlideTransition(
        position: _exitSlide,
        child: FadeTransition(
          opacity: _exitFade,
          child: Align(
            alignment: Alignment.topCenter,
            child: AspectRatio(
              aspectRatio: SwipeableCard.cardAspectRatio,
              child: _buildCard(cardData, depth: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeOverlay() {
    final theme = Theme.of(context);
    final likeOpacity = (_dragOffset.dx / 80.0).clamp(0.0, 1.0);
    final nopeOpacity = ((-_dragOffset.dx) / 80.0).clamp(0.0, 1.0);
    final superOpacity = ((-_dragOffset.dy) / 60.0).clamp(0.0, 1.0);
    final likeColor = theme.colorScheme.tertiary;
    final nopeColor = theme.colorScheme.error;
    final superColor = AppColors.warningYellow;

    Widget label({
      required String text,
      required Color color,
      required double opacity,
      required double angle,
    }) {
      return Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: color,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              text,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
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
            top: 20,
            left: 20,
            child: label(
              text: 'LIKE',
              color: likeColor,
              opacity: likeOpacity,
              angle: -0.2,
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: label(
              text: 'NOPE',
              color: nopeColor,
              opacity: nopeOpacity,
              angle: 0.2,
            ),
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: label(
                text: 'SUPER',
                color: superColor,
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
      key: ValueKey('discover_card_$userId'),
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
    final direction = action == 'like'
        ? const Offset(1.2, 0)
        : const Offset(-1.2, 0);

    if (!AppAnimations.animationsEnabled(context)) {
      widget.onSwipe?.call(userId, action);
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
      _dragOffset = Offset.zero;
    });

    widget.onSwipe?.call(userId, action);

    _exitController
      ..reset()
      ..addStatusListener(_onExitStatus)
      ..forward();
  }
}
