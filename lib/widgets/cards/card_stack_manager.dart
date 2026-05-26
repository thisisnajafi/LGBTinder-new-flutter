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
import '../../core/utils/app_icons.dart';

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
    Key? key,
    required this.cards,
    this.onSwipe,
    this.onCardTap,
    this.isLoading = false,
    this.onRefresh,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.emptySecondaryActionLabel,
    this.onEmptySecondaryAction,
  }) : super(key: key);

  @override
  ConsumerState<CardStackManager> createState() => _CardStackManagerState();
}

class _CardStackManagerState extends ConsumerState<CardStackManager>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int? _exitingIndex;
  int? _pendingSwipeUserId;
  String? _pendingSwipeAction;
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
      CurvedAnimation(parent: _exitController, curve: AppAnimations.curveDefault),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: AppAnimations.curveDefault),
    );
  }

  @override
  void didUpdateWidget(CardStackManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards.length != oldWidget.cards.length && _exitingIndex == null) {
      _currentIndex = 0;
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
    final userId = _pendingSwipeUserId;
    final action = _pendingSwipeAction;
    _pendingSwipeUserId = null;
    _pendingSwipeAction = null;
    if (mounted) {
      setState(() {
        _exitingIndex = null;
        _dragOffset = Offset.zero;
      });
      if (userId != null && action != null) {
        widget.onSwipe?.call(userId, action);
      }
    }
  }

  double get _swipeThreshold =>
      MediaQuery.sizeOf(context).width * 0.22;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_exitingIndex != null) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_exitingIndex != null) return;
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

    if (widget.cards.isEmpty) {
      return EmptyState(
        title: 'No more profiles',
        message: 'Try widening filters or expanding distance to find more people.',
        icon: Icons.person_outline,
        actionLabel:
            widget.emptyActionLabel ?? (widget.onRefresh != null ? 'Refresh' : null),
        onAction: widget.onEmptyAction ?? widget.onRefresh,
        secondaryActionLabel: widget.emptySecondaryActionLabel,
        onSecondaryAction: widget.onEmptySecondaryAction,
      );
    }

    if (_currentIndex >= widget.cards.length) {
      return EmptyState(
        title: 'You\'ve seen everyone!',
        message: 'Check back later for new matches',
        iconPath: AppIcons.favoriteBorder,
        actionLabel: widget.onRefresh != null ? 'Refresh' : null,
        onAction: widget.onRefresh,
      );
    }

    final currentCard = widget.cards[_currentIndex];

    return Stack(
      children: [
        if (_currentIndex + 1 < widget.cards.length)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.spacingMD,
                top: AppSpacing.spacingMD,
              ),
              child: _buildCard(widget.cards[_currentIndex + 1], 1),
            ),
          ),
        if (_currentIndex + 2 < widget.cards.length)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.spacingSM,
                top: AppSpacing.spacingSM,
              ),
              child: _buildCard(widget.cards[_currentIndex + 2], 2),
            ),
          ),
        Positioned.fill(
          child: _buildCurrentCard(currentCard),
        ),
      ],
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
                color: isLike ? AppColors.onlineGreen : AppColors.notificationRed,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isLike ? 'LIKE' : 'NOPE',
              style: AppTypography.h2.copyWith(
                color: isLike ? AppColors.onlineGreen : AppColors.notificationRed,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCard(Map<String, dynamic> currentCard) {
    final content = _buildCard(currentCard, 0);
    final width = MediaQuery.sizeOf(context).width;
    final rotation = (_dragOffset.dx / width * 0.12).clamp(-0.15, 0.15);

    Widget card = content;
    if (_exitingIndex != null) {
      card = SlideTransition(
        position: _exitSlide,
        child: FadeTransition(
          opacity: _exitFade,
          child: content,
        ),
      );
    } else {
      card = Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              content,
              _buildSwipeOverlay(),
            ],
          ),
        ),
      );
    }

    if (_exitingIndex != null) return card;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: card,
    );
  }

  Widget _buildCard(Map<String, dynamic> cardData, int index) {
    final opacity = 1.0 - (index * 0.2);
    final scale = 1.0 - (index * 0.05);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: SwipeableCard(
          userId: cardData['id'] ?? 0,
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
          onLike: index == 0 ? () => _handleAction('like') : null,
          onDislike: index == 0 ? () => _handleAction('dislike') : null,
          onSuperlike: index == 0 ? () => _handleAction('superlike') : null,
          onTap: () => widget.onCardTap?.call(cardData['id'] ?? 0),
        ),
      ),
    );
  }

  void _handleAction(String action) {
    if (_currentIndex >= widget.cards.length || _exitingIndex != null) return;

    if (action == 'superlike') {
      final userId = widget.cards[_currentIndex]['id'] as int? ?? 0;
      widget.onSwipe?.call(userId, 'superlike');
      return;
    }

    final currentCard = widget.cards[_currentIndex];
    final userId = currentCard['id'] as int? ?? 0;

    final direction = action == 'like'
        ? const Offset(1.2, 0)
        : const Offset(-1.2, 0);

    if (!AppAnimations.animationsEnabled(context)) {
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
      });
      widget.onSwipe?.call(userId, action);
      return;
    }

    _pendingSwipeUserId = userId;
    _pendingSwipeAction = action;
    _exitSlide = Tween<Offset>(begin: Offset.zero, end: direction).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: AppAnimations.curveDefault,
      ),
    );
    setState(() {
      _exitingIndex = _currentIndex;
      _dragOffset = Offset.zero;
    });
    _exitController
      ..reset()
      ..addStatusListener(_onExitStatus)
      ..forward();
  }
}
