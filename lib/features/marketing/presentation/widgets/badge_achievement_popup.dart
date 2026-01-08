import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/badge_model.dart';
import 'badge_display.dart';

/// Badge achievement popup widget
/// Shows animated celebration when user earns a badge
/// Part of the Marketing System Implementation (Task 3.4.5)
class BadgeAchievementPopup extends ConsumerStatefulWidget {
  final BadgeModel badge;
  final VoidCallback? onDismiss;
  final VoidCallback? onClaimReward;
  final VoidCallback? onShare;

  const BadgeAchievementPopup({
    Key? key,
    required this.badge,
    this.onDismiss,
    this.onClaimReward,
    this.onShare,
  }) : super(key: key);

  /// Shows the achievement popup as a dialog
  static Future<void> show(
    BuildContext context,
    BadgeModel badge, {
    VoidCallback? onClaimReward,
    VoidCallback? onShare,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeAchievementPopup(
        badge: badge,
        onDismiss: () => Navigator.of(context).pop(),
        onClaimReward: onClaimReward,
        onShare: onShare,
      ),
    );
  }

  @override
  ConsumerState<BadgeAchievementPopup> createState() =>
      _BadgeAchievementPopupState();
}

class _BadgeAchievementPopupState extends ConsumerState<BadgeAchievementPopup>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Main scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Badge bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _scaleController.forward();
    _bounceController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color get _badgeColor {
    switch (widget.badge.rarity?.toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFD700);
      case 'epic':
        return AppColors.accentPurple;
      case 'rare':
        return const Color(0xFF2196F3);
      case 'uncommon':
        return AppColors.onlineGreen;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: [
                _badgeColor,
                AppColors.accentPurple,
                AppColors.accentGradientEnd,
                Colors.yellow,
                Colors.pink,
              ],
            ),
          ),

          // Main content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _badgeColor.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      '🎉 Achievement Unlocked!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _badgeColor,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Animated badge
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _bounceAnimation,
                        _glowAnimation,
                      ]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _bounceAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _badgeColor
                                      .withOpacity(0.3 * _glowAnimation.value),
                                  spreadRadius: 10 * _glowAnimation.value,
                                  blurRadius: 30 * _glowAnimation.value,
                                ),
                              ],
                            ),
                            child: BadgeDisplay(
                              badge: widget.badge,
                              size: 100,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Badge name
                    Text(
                      widget.badge.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Rarity badge
                    if (widget.badge.rarity != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _badgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _badgeColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          widget.badge.rarity!.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _badgeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Description
                    if (widget.badge.description != null)
                      Text(
                        widget.badge.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                    // Reward info
                    if (widget.badge.reward != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentYellow.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              color: AppColors.accentYellow,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reward: ${_formatReward(widget.badge.reward!)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.accentYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Action buttons
                    Row(
                      children: [
                        // Share button
                        if (widget.onShare != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onShare,
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                        if (widget.onShare != null) const SizedBox(width: 12),

                        // Claim/Continue button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.badge.reward != null &&
                                    !widget.badge.rewardClaimed
                                ? () {
                                    widget.onClaimReward?.call();
                                    widget.onDismiss?.call();
                                  }
                                : widget.onDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _badgeColor,
                              foregroundColor: _badgeColor == Colors.yellow ||
                                      _badgeColor == const Color(0xFFFFD700)
                                  ? Colors.black
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.badge.reward != null &&
                                      !widget.badge.rewardClaimed
                                  ? 'Claim Reward'
                                  : 'Awesome!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 48,
            right: 16,
            child: IconButton(
              onPressed: widget.onDismiss,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReward(Map<String, dynamic> reward) {
    final type = reward['type']?.toString() ?? '';
    final amount = reward['amount'] ?? 0;

    switch (type) {
      case 'superlikes':
        return '$amount Super Likes';
      case 'boosts':
        return '$amount Boosts';
      case 'premium_days':
        return '$amount Premium Days';
      case 'profile_views':
        return '$amount Profile Views';
      default:
        return '$amount $type';
    }
  }
}

/// Multiple badge achievement popup for batch awards
class MultipleBadgeAchievementPopup extends ConsumerStatefulWidget {
  final List<BadgeModel> badges;
  final VoidCallback? onDismiss;

  const MultipleBadgeAchievementPopup({
    Key? key,
    required this.badges,
    this.onDismiss,
  }) : super(key: key);

  static Future<void> show(BuildContext context, List<BadgeModel> badges) {
    if (badges.isEmpty) return Future.value();

    if (badges.length == 1) {
      return BadgeAchievementPopup.show(context, badges.first);
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MultipleBadgeAchievementPopup(
        badges: badges,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  ConsumerState<MultipleBadgeAchievementPopup> createState() =>
      _MultipleBadgeAchievementPopupState();
}

class _MultipleBadgeAchievementPopupState
    extends ConsumerState<MultipleBadgeAchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎉 ${widget.badges.length} Badges Unlocked!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // Badge grid
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: widget.badges
                      .map((badge) => BadgeDisplay(
                            badge: badge,
                            size: 64,
                            showLabel: true,
                          ))
                      .toList(),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
}
