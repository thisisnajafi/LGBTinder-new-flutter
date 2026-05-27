// Widget: CardStackManager
// Card stack manager with horizontal swipe gestures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/constants/animation_constants.dart';
import 'swipeable_card.dart';
import '../error_handling/empty_state.dart';
import '../../core/widgets/loading_indicator.dart';

/// Card stack manager widget
/// Manages a stack of swipeable cards for discovery screen
class CardStackManager extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> cards;
  final Function(int userId, String action)? onSwipe;
  final Function(int userId)? onCardTap;
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
    this.onCardTap,
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
      return EmptyState(
        title: 'No more profiles',
        message:
            'Try widening filters or expanding distance to find more people.',
        icon: Icons.person_outline,
        actionLabel: widget.emptyActionLabel ??
            (widget.onRefresh != null ? 'Refresh' : null),
        onAction: widget.onEmptyAction ?? widget.onRefresh,
        secondaryActionLabel: widget.emptySecondaryActionLabel,
        onSecondaryAction: widget.onEmptySecondaryAction,
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
    if (_dragOffset.dx.abs() < 12) return const SizedBox.shrink();

    final isLike = _dragOffset.dx > 0;
    final opacity = (_dragOffset.dx.abs() / _swipeThreshold).clamp(0.0, 1.0);

    return Positioned(
      top: 48,
      left: isLike ? 32 : null,
      right: isLike ? null : 32,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: isLike ? -0.35 : 0.35,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingMD,
              vertical: AppSpacing.spacingSM,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isLike ? AppColors.onlineGreen : AppColors.notificationRed,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLike ? 'LIKE' : 'NOPE',
              style: AppTypography.h2.copyWith(
                color:
                    isLike ? AppColors.onlineGreen : AppColors.notificationRed,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
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

    return SwipeableCard(
      key: ValueKey('discover_card_$userId'),
      userId: userId,
      name: cardData['name'] ?? 'User',
      age: cardData['age'],
      location: cardData['location'],
      avatarUrl: cardData['avatar_url'],
      imageUrls: cardData['image_urls']?.cast<String>(),
      bio: cardData['bio'],
      isVerified: cardData['is_verified'] ?? false,
      isPremium: cardData['is_premium'] ?? false,
      distance: cardData['distance']?.toDouble(),
      compatibilityScore: (cardData['compatibility_score'] as num?)?.toInt(),
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
      onTap: () => widget.onCardTap?.call(userId),
    );
  }

  void _handleAction(String action) {
    if (widget.cards.isEmpty || _exitingCardSnapshot != null) return;

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
