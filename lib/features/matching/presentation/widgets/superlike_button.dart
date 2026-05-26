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

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.curveDefault,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
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
                onPressed: (matchingState.isSuperliking || !widget.isPremium || _isSending)
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
    if (_isSending) return;
    if (!widget.isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    setState(() => _isSending = true);

    _animationController.forward().then((_) {
      if (mounted) _animationController.reverse();
    });

    final matchingNotifier = ref.read(matchingProvider.notifier);

    try {
      final response = await matchingNotifier.superlikeProfile(widget.profileId);

      if (!mounted) return;
      if (response != null && response.isMatch && response.match != null) {
        await notifyNewMatch(ref);
        MatchCelebrationLauncher.show(context, ref, match: response.match!);
        widget.onSuperlikeSuccess?.call();
      } else {
        widget.onSuperlikeSuccess?.call();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Superlike send failed',
        tag: 'SuperlikeButton',
        error: e,
        stackTrace: stack,
      );
      if (mounted) widget.onSuperlikeError?.call();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
    if (mounted && _animationController.status == AnimationStatus.completed) {
      _animationController.reverse();
    }
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
}
