import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../models/match.dart';

/// Match celebration widget
/// Shows animated celebration when users match
class MatchCelebration extends ConsumerStatefulWidget {
  final Match match;
  final bool isSuperMatch;
  final VoidCallback? onSendMessage;
  final VoidCallback? onKeepSwiping;

  const MatchCelebration({
    Key? key,
    required this.match,
    this.isSuperMatch = false,
    this.onSendMessage,
    this.onKeepSwiping,
  }) : super(key: key);

  @override
  ConsumerState<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends ConsumerState<MatchCelebration>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Scale animation for the main content
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Bounce animation for icons
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    _scaleController.forward();
    _bounceController.repeat(reverse: true);
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: widget.isSuperMatch
                  ? [
                      AppColors.primaryLight,
                      AppColors.secondaryLight,
                      Colors.yellow,
                      Colors.pink,
                      Colors.purple,
                    ]
                  : [
                      AppColors.feedbackSuccess,
                      Colors.pink,
                      Colors.blue,
                      Colors.yellow,
                      Colors.purple,
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
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Celebration icon
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _bounceAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: widget.isSuperMatch
                                    ? [
                                        AppColors.primaryLight,
                                        AppColors.secondaryLight,
                                      ]
                                    : [
                                        AppColors.feedbackSuccess,
                                        Colors.green,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              widget.isSuperMatch ? Icons.star : Icons.favorite,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      widget.isSuperMatch ? 'Super Match!' : 'It\'s a Match!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'You and ${widget.match.firstName} liked each other!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Profile info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Current user placeholder
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Heart icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.feedbackError.withOpacity(0.1),
                          ),
                          child: Icon(
                            Icons.favorite,
                            color: AppColors.feedbackError,
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Matched user
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: widget.match.primaryImageUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    widget.match.primaryImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 30,
                                        ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: Colors.grey[600],
                                  size: 30,
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onKeepSwiping ?? () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Keep Swiping',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onSendMessage ?? () {
                              Navigator.of(context).pop();
                              // Navigate to chat screen with the matched user
                              context.go('/chat/${widget.match.matchedUser.id}');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Send Message',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
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
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
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
}
