import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import '../../providers/matching_provider.dart';
import '../../widgets/match_celebration_launcher.dart';

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
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.tapDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.curveDefault,
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.curveDefault,
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
              onPressed: (matchingState.isLiking || _isSending) ? null : _handleLike,
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
    if (_isSending) return;
    setState(() => _isSending = true);

    _animationController.forward();

    final matchingNotifier = ref.read(matchingProvider.notifier);

    try {
      final response = await matchingNotifier.likeProfile(widget.profileId);

      if (!mounted) return;
      if (response != null && response.isMatch && response.match != null) {
        await notifyNewMatch(ref);
        MatchCelebrationLauncher.show(context, ref, match: response.match!);
        widget.onLikeSuccess?.call();
      } else {
        widget.onLikeSuccess?.call();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Like send failed',
        tag: 'LikeButton',
        error: e,
        stackTrace: stack,
      );
      if (mounted) widget.onLikeError?.call();
    } finally {
      if (mounted) {
        await _animationController.reverse();
        setState(() => _isSending = false);
      }
    }
  }

}
