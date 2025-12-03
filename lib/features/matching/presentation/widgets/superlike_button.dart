import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../../providers/matching_provider.dart';

/// Superlike button widget
/// Handles superliking profiles with premium styling and effects
class SuperlikeButton extends ConsumerStatefulWidget {
  final int profileId;
  final double size;
  final bool showLabel;
  final bool isPremium;
  final VoidCallback? onSuperlikeSuccess;
  final VoidCallback? onSuperlikeError;

  const SuperlikeButton({
    Key? key,
    required this.profileId,
    this.size = 48,
    this.showLabel = false,
    this.isPremium = true,
    this.onSuperlikeSuccess,
    this.onSuperlikeError,
  }) : super(key: key);

  @override
  ConsumerState<SuperlikeButton> createState() => _SuperlikeButtonState();
}

class _SuperlikeButtonState extends ConsumerState<SuperlikeButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingState = ref.watch(matchingProvider);
    final matchingNotifier = ref.read(matchingProvider.notifier);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: widget.size + 16,
              height: widget.size + 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.isPremium
                      ? [
                          AppColors.primaryLight.withOpacity(0.8),
                          AppColors.primaryLight,
                          AppColors.secondaryLight,
                        ]
                      : [
                          Colors.grey.withOpacity(0.8),
                          Colors.grey,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isPremium
                        ? AppColors.primaryLight.withOpacity(0.4 + (_glowAnimation.value * 0.3))
                        : Colors.grey.withOpacity(0.3),
                    spreadRadius: 2 + (_glowAnimation.value * 3),
                    blurRadius: 8 + (_glowAnimation.value * 4),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (matchingState.isSuperliking || !widget.isPremium)
                    ? null
                    : _handleSuperlike,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  minimumSize: Size(widget.size, widget.size),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    matchingState.isSuperliking
                        ? SizedBox(
                            width: widget.size * 0.4,
                            height: widget.size * 0.4,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : AppSvgIcon(
                            assetPath: AppIcons.star,
                            size: widget.size * 0.5,
                            color: Colors.white,
                          ),
                    if (widget.showLabel) ...[
                      const SizedBox(height: 2),
                      Text(
                        matchingState.isSuperliking
                            ? 'Superliking...'
                            : widget.isPremium
                                ? 'Super Like'
                                : 'Premium',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSuperlike() async {
    if (!widget.isPremium) {
      // Show premium upgrade dialog
      _showPremiumRequiredDialog();
      return;
    }

    // Start animation
    await _animationController.forward();

    final matchingNotifier = ref.read(matchingProvider.notifier);

    try {
      final response = await matchingNotifier.superlikeProfile(widget.profileId);

      if (response != null && response.isMatch) {
        // Show enhanced match celebration for superlikes
        _showSuperMatchCelebration();
        widget.onSuperlikeSuccess?.call();
      } else {
        widget.onSuperlikeSuccess?.call();
      }
    } catch (e) {
      widget.onSuperlikeError?.call();
    }

    // Reset animation
    await _animationController.reverse();
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Super Likes are a premium feature. Upgrade to premium to send Super Likes and increase your chances of matching!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to premium upgrade screen
              context.go('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showSuperMatchCelebration() {
    // Show enhanced match celebration for superlikes with confetti
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryLight,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⭐ SUPER MATCH! ⭐',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'You both superliked each other!\nThis is extra special! 🎉✨',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ),
      ),
    );

    // Also show a snackbar for additional feedback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Super Match! Both users superliked each other! ⭐🎉'),
            backgroundColor: AppColors.primaryLight,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }
}
