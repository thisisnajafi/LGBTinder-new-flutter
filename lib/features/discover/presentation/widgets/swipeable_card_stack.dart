import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/discovery_provider.dart';
import 'profile_card.dart';

/// Swipeable card stack widget for discovery
/// Handles swiping gestures and card animations
class SwipeableCardStack extends ConsumerStatefulWidget {
  final double cardHeight;
  final int maxCardsToShow;

  const SwipeableCardStack({
    Key? key,
    this.cardHeight = 500,
    this.maxCardsToShow = 3,
  }) : super(key: key);

  @override
  ConsumerState<SwipeableCardStack> createState() => _SwipeableCardStackState();
}

class _SwipeableCardStackState extends ConsumerState<SwipeableCardStack>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final discoveryNotifier = ref.read(discoveryProvider.notifier);

    if (discoveryState.isLoading) {
      return _buildLoadingState();
    }

    if (discoveryState.profiles.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: widget.cardHeight,
      child: Stack(
        children: List.generate(
          discoveryState.profiles.length.clamp(0, widget.maxCardsToShow),
          (index) {
            final profileIndex = discoveryState.currentIndex + index;
            if (profileIndex >= discoveryState.profiles.length) {
              return const SizedBox.shrink();
            }

            final profile = discoveryState.profiles[profileIndex];
            final isTopCard = index == 0;

            return _buildCard(
              profile: profile,
              index: index,
              isTopCard: isTopCard,
              discoveryNotifier: discoveryNotifier,
            );
          },
        ).reversed.toList(), // Reverse to show top card on top
      ),
    );
  }

  Widget _buildCard({
    required DiscoveryProfile profile,
    required int index,
    required bool isTopCard,
    required DiscoveryNotifier discoveryNotifier,
  }) {
    final scale = index == 0 ? 1.0 : (1.0 - (index * 0.05));
    final topPosition = index * 8.0;

    return Positioned(
      top: topPosition,
      left: 16,
      right: 16,
      bottom: 0,
      child: Transform.scale(
        scale: scale,
        child: isTopCard
            ? _buildDraggableCard(profile, discoveryNotifier)
            : ProfileCard(
                profile: profile,
                isPreview: true,
              ),
      ),
    );
  }

  Widget _buildDraggableCard(DiscoveryProfile profile, DiscoveryNotifier discoveryNotifier) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onPanEnd: (details) async {
        setState(() {
          _isDragging = false;
        });

        // Determine swipe direction and action
        if (_dragOffset.dx.abs() > 100) {
          // Swipe action
          if (_dragOffset.dx > 0) {
            // Swipe right - Like
            await discoveryNotifier.likeCurrentProfile();
          } else {
            // Swipe left - Dislike
            await discoveryNotifier.dislikeCurrentProfile();
          }
        } else if (_dragOffset.dy < -100) {
          // Swipe up - Superlike
          await discoveryNotifier.superlikeCurrentProfile();
        }

        // Reset position
        setState(() {
          _dragOffset = Offset.zero;
        });
      },
      child: Transform.translate(
        offset: _isDragging ? _dragOffset : Offset.zero,
        child: Transform.rotate(
          angle: _isDragging ? (_dragOffset.dx * 0.001) : 0.0,
          child: Stack(
            children: [
              ProfileCard(
                profile: profile,
                isInteractive: true,
              ),
              // Swipe indicators
              if (_isDragging) _buildSwipeIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeIndicators() {
    final isLike = _dragOffset.dx > 50;
    final isDislike = _dragOffset.dx < -50;
    final isSuperlike = _dragOffset.dy < -50;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLike
                ? AppColors.feedbackSuccess
                : isDislike
                    ? AppColors.feedbackError
                    : isSuperlike
                        ? AppColors.primaryLight
                        : Colors.transparent,
            width: 4,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: (isLike || isDislike || isSuperlike)
                  ? Colors.white.withOpacity(0.9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              isLike
                  ? 'LIKE'
                  : isDislike
                      ? 'NOPE'
                      : isSuperlike
                          ? 'SUPER LIKE'
                          : '',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLike
                    ? AppColors.feedbackSuccess
                    : isDislike
                        ? AppColors.feedbackError
                        : isSuperlike
                            ? AppColors.primaryLight
                            : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Finding matches...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No more profiles to show',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new matches!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
