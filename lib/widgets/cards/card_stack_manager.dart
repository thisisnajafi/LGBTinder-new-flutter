// Widget: CardStackManager
// Card stack manager
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing_constants.dart';
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

  const CardStackManager({
    Key? key,
    required this.cards,
    this.onSwipe,
    this.onCardTap,
    this.isLoading = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  ConsumerState<CardStackManager> createState() => _CardStackManagerState();
}

class _CardStackManagerState extends ConsumerState<CardStackManager> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return LoadingIndicator(message: 'Loading profiles...');
    }

    if (widget.cards.isEmpty) {
      return EmptyState(
        title: 'No more profiles',
        message: 'Check back later for new matches!',
        icon: Icons.person_outline,
        actionLabel: widget.onRefresh != null ? 'Refresh' : null,
        onAction: widget.onRefresh,
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
        // Background cards (next 2)
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
        // Current card
        _buildCard(currentCard, 0),
      ],
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
          onLike: index == 0 ? () => _handleAction('like') : null,
          onDislike: index == 0 ? () => _handleAction('dislike') : null,
          onSuperlike: index == 0 ? () => _handleAction('superlike') : null,
          onTap: () => widget.onCardTap?.call(cardData['id'] ?? 0),
        ),
      ),
    );
  }

  void _handleAction(String action) {
    if (_currentIndex >= widget.cards.length) return;

    final currentCard = widget.cards[_currentIndex];
    widget.onSwipe?.call(currentCard['id'] ?? 0, action);

    setState(() {
      _currentIndex++;
    });
  }
}
