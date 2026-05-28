// Widget: CardStackManager
// Card stack manager with horizontal swipe gestures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/constants/animation_constants.dart';
import 'swipeable_card.dart';
import '../../features/discover/widgets/discover_empty_state.dart';
import '../../core/widgets/loading_indicator.dart';

/// Card stack manager widget
/// Manages a stack of swipeable cards for discovery screen
class CardStackManager extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> cards;
  final Function(int userId, String action)? onSwipe;
  final Function(int userId)? onViewProfile;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? emptySecondaryActionLabel;
  final VoidCallback? onEmptySecondaryAction;

  const CardStackManager({
    super.key,
    required this.cards,
    this.onSwipe,
    this.onViewProfile,
    this.isLoading = false,
    this.onRefresh,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.emptySecondaryActionLabel,
    this.onEmptySecondaryAction,
  });

  @override
  ConsumerState<CardStackManager> createState() => _CardStackManagerState();
}

class _CardStackManagerState extends ConsumerState<CardStackManager>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _exitingCardSnapshot;
  Offset _dragOffset = Offset.zero;
  bool _isCardExpanded = false;
  late AnimationController _exitController;
  late Animation<Offset> _exitSlide;
  late Animation<double> _exitFade;

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
  }

  @override
  void didUpdateWidget(CardStackManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTopId =
        oldWidget.cards.isNotEmpty ? oldWidget.cards.first['id'] : null;
    final newTopId = widget.cards.isNotEmpty ? widget.cards.first['id'] : null;
    if (oldTopId != newTopId) {
      _isCardExpanded = false;
    }
    if (widget.cards.isEmpty && _exitingCardSnapshot == null) {
      _dragOffset = Offset.zero;
    }
  }

  @override
  void dispose() {
    _exitController.removeStatusListener(_onExitStatus);
    _exitController.dispose();
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
    if (_exitingCardSnapshot != null) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_exitingCardSnapshot != null) return;
    final isPrimarilyVertical =
        _dragOffset.dy.abs() > (_dragOffset.dx.abs() * 1.35);
    if (isPrimarilyVertical) {
      if (_dragOffset.dy < -100 || details.velocity.pixelsPerSecond.dy < -300) {
        setState(() {
          _isCardExpanded = true;
          _dragOffset = Offset.zero;
        });
        return;
      }
      if (_isCardExpanded &&
          (_dragOffset.dy > 100 || details.velocity.pixelsPerSecond.dy > 300)) {
        setState(() {
          _isCardExpanded = false;
          _dragOffset = Offset.zero;
        });
        return;
      }
    }
    if (_isCardExpanded) {
      setState(() => _dragOffset = Offset.zero);
      return;
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

    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
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

  Widget _buildStackCard(Map<String, dynamic> cardData, {required int depth}) {
    final scale = 1.0 - (depth * 0.04);
    final topInset = depth * AppSpacing.spacingSM;

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: _buildCard(
            cardData,
            depth: depth,
            isBackgroundPreview: depth > 0,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveTopCard(Map<String, dynamic> cardData) {
    final width = MediaQuery.sizeOf(context).width;
    final rotation = (_dragOffset.dx / width * 0.12).clamp(-0.15, 0.15);

    return Positioned.fill(
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.translate(
          offset: _dragOffset,
          child: Transform.rotate(
            angle: rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildCard(cardData, depth: 0),
                _buildSwipeOverlay(),
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
          child: _buildCard(cardData, depth: 0),
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
    final superColor = theme.colorScheme.primary;

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

    return SwipeableCard(
      key: ValueKey('discover_card_$userId'),
      userId: userId,
      name: cardData['name'] ?? 'User',
      age: cardData['age'],
      location: cardData['location'],
      avatarUrl: cardData['avatar_url'],
      imageUrls: cardData['image_urls']?.cast<String>(),
      bio: cardData['bio'],
      interests: (cardData['interests'] as List?)
          ?.map((item) => item.toString())
          .toList(),
      sharedInterests: (cardData['shared_interests'] as List?)
          ?.map((item) => item.toString())
          .toList(),
      jobTitle: cardData['job']?.toString() ?? cardData['job_title']?.toString(),
      educationTitle: cardData['education']?.toString() ??
          cardData['education_title']?.toString(),
      isVerified: cardData['is_verified'] ?? false,
      isPremium: cardData['is_premium'] ?? false,
      distance: cardData['distance']?.toDouble(),
      compatibilityScore: (cardData['compatibility_score'] as num?)?.toInt(),
      isExpanded: depth == 0 ? _isCardExpanded : false,
      onExpandedChanged: depth == 0
          ? (expanded) {
              setState(() {
                _isCardExpanded = expanded;
              });
            }
          : null,
      isBackgroundPreview: isBackgroundPreview,
      onLike: depth == 0 && _exitingCardSnapshot == null
          ? () => _handleAction('like')
          : null,
      onDislike: depth == 0 && _exitingCardSnapshot == null
          ? () => _handleAction('dislike')
          : null,
      onSuperlike: depth == 0 && _exitingCardSnapshot == null
          ? () => _handleAction('superlike')
          : null,
      onViewProfile: depth == 0
          ? () => widget.onViewProfile?.call(userId)
          : null,
    );
  }

  void _handleAction(String action) {
    if (widget.cards.isEmpty || _exitingCardSnapshot != null) return;

    if (action == 'superlike') {
      final userId = widget.cards[0]['id'] as int? ?? 0;
      if (_isCardExpanded) {
        setState(() => _isCardExpanded = false);
      }
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
      _isCardExpanded = false;
    });

    widget.onSwipe?.call(userId, action);

    _exitController
      ..reset()
      ..addStatusListener(_onExitStatus)
      ..forward();
  }
}
