import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../../providers/matching_provider.dart';

/// Like button widget
/// Handles liking profiles with visual feedback
class LikeButton extends ConsumerStatefulWidget {
  final int profileId;
  final double size;
  final bool showLabel;
  final VoidCallback? onLikeSuccess;
  final VoidCallback? onLikeError;

  const LikeButton({
    Key? key,
    required this.profileId,
    this.size = 56,
    this.showLabel = false,
    this.onLikeSuccess,
    this.onLikeError,
  }) : super(key: key);

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
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
  Widget build(BuildContext context) {
    final matchingState = ref.watch(matchingProvider);
    final matchingNotifier = ref.read(matchingProvider.notifier);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size + 16,
            height: widget.size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.feedbackSuccess.withOpacity(0.8),
                  AppColors.feedbackSuccess,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.feedbackSuccess.withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: matchingState.isLiking ? null : _handleLike,
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
                  Transform.scale(
                    scale: _iconScaleAnimation.value,
                    child: matchingState.isLiking
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
                            assetPath: AppIcons.heart,
                            size: widget.size * 0.5,
                            color: Colors.white,
                          ),
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(height: 2),
                    Text(
                      matchingState.isLiking ? 'Liking...' : 'Like',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLike() async {
    // Start animation
    await _animationController.forward();

    final matchingNotifier = ref.read(matchingProvider.notifier);

    try {
      final response = await matchingNotifier.likeProfile(widget.profileId);

      if (response != null && response.isMatch) {
        // Show match celebration animation
        _showMatchCelebration();
        widget.onLikeSuccess?.call();
      } else {
        widget.onLikeSuccess?.call();
      }
    } catch (e) {
      widget.onLikeError?.call();
    }

    // Reset animation
    await _animationController.reverse();
  }

  void _showMatchCelebration() {
    // TODO: Show match celebration overlay/screen
    // This could navigate to a match screen or show a celebration dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('It\'s a match! 🎉'),
        backgroundColor: AppColors.feedbackSuccess,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
