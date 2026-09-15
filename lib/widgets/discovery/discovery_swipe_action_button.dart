import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_icons.dart';

/// Dislike, superlike, like, or rewind action on the discover screen.
enum DiscoverySwipeActionType { rewind, dislike, superlike, like }

/// Circular discover action button with gradient fill, border, and glow.
class DiscoverySwipeActionButton extends StatefulWidget {
  const DiscoverySwipeActionButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.size = 58,
  });

  final DiscoverySwipeActionType type;
  final VoidCallback? onPressed;
  final double size;

  @override
  State<DiscoverySwipeActionButton> createState() =>
      _DiscoverySwipeActionButtonState();
}

class _DiscoverySwipeActionButtonState extends State<DiscoverySwipeActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.transitionModal,
      reverseDuration: AppAnimations.feedbackShort,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeOutCubic,
      ),
    );
    _rotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 0.1,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 120,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.1,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 130,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _animatePressDown(bool disableAnimations) async {
    if (disableAnimations) return;
    _controller.duration = AppAnimations.tapDuration;
    await _controller.animateTo(0.4, curve: AppAnimations.curveDefault);
  }

  Future<void> _animateRelease(bool disableAnimations) async {
    if (disableAnimations) return;
    _controller.reverseDuration = AppAnimations.feedbackShort;
    await _controller.animateBack(0.0, curve: AppAnimations.curveDefault);
  }

  Future<void> _animateSuperlikePulse(bool disableAnimations) async {
    if (disableAnimations ||
        widget.type != DiscoverySwipeActionType.superlike) {
      return;
    }
    _controller.duration = AppAnimations.transitionModal;
    await _controller.forward(from: 0);
  }

  _SwipeActionVisuals _visualsFor(BuildContext context) {
    switch (widget.type) {
      case DiscoverySwipeActionType.rewind:
        return _SwipeActionVisuals(
          gradient: const LinearGradient(
            colors: [AppColors.accentViolet, AppColors.accentPurple],
          ),
          borderColor: AppColors.accentViolet,
          glowColor: AppColors.accentViolet,
          iconPath: AppIcons.refresh,
          semanticLabel: 'Rewind last swipe',
          iconColor: Colors.white,
        );
      case DiscoverySwipeActionType.dislike:
        return _SwipeActionVisuals(
          gradient: AppColors.discoverDislikeGradient,
          borderColor: AppColors.feedbackError.withValues(alpha: 0.55),
          glowColor: AppColors.feedbackError,
          iconPath: AppIcons.close,
          semanticLabel: 'Dislike profile',
          iconColor: Colors.white,
        );
      case DiscoverySwipeActionType.superlike:
        return _SwipeActionVisuals(
          gradient: AppColors.discoverSuperlikeGradient,
          borderColor: AppColors.warningYellow.withValues(alpha: 0.7),
          glowColor: AppColors.warningYellow,
          iconPath: AppIcons.star,
          semanticLabel: 'Super like profile',
          iconColor: AppColors.textPrimaryLight,
        );
      case DiscoverySwipeActionType.like:
        return _SwipeActionVisuals(
          gradient: AppColors.discoverLikeGradient,
          borderColor: AppColors.onlineGreen.withValues(alpha: 0.55),
          glowColor: AppColors.onlineGreen,
          iconPath: AppIcons.heart,
          semanticLabel: 'Like profile',
          iconColor: Colors.white,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final visuals = _visualsFor(context);
    final touchSize = widget.size < 48 ? 48.0 : widget.size;
    final iconSize = widget.type == DiscoverySwipeActionType.superlike
        ? widget.size * 0.44
        : widget.size * 0.42;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: visuals.semanticLabel,
      child: RepaintBoundary(
        child: SizedBox(
          width: touchSize,
          height: touchSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _animatePressDown(disableAnimations),
            onTapCancel: () => _animateRelease(disableAnimations),
            onTapUp: (_) => _animateRelease(disableAnimations),
            onTap: widget.onPressed == null
                ? null
                : () async {
                    AppHaptics.light();
                    await _animateSuperlikePulse(disableAnimations);
                    widget.onPressed?.call();
                  },
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = disableAnimations ? 1.0 : _scale.value;
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final turns =
                      (widget.type == DiscoverySwipeActionType.superlike &&
                          !disableAnimations)
                      ? _rotation.value
                      : 0.0;
                  return RotationTransition(
                    turns: AlwaysStoppedAnimation<double>(turns),
                    child: child,
                  );
                },
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: visuals.gradient,
                    border: Border.all(color: visuals.borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: visuals.glowColor.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: Center(
                        child: AppSvgIcon(
                          assetPath: visuals.iconPath,
                          size: iconSize,
                          color: visuals.iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeActionVisuals {
  const _SwipeActionVisuals({
    required this.gradient,
    required this.borderColor,
    required this.glowColor,
    required this.iconPath,
    required this.semanticLabel,
    required this.iconColor,
  });

  final Gradient gradient;
  final Color borderColor;
  final Color glowColor;
  final String iconPath;
  final String semanticLabel;
  final Color iconColor;
}
