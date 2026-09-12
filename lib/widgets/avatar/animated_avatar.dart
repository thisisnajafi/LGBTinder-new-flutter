// Widget: AnimatedAvatar
// Animated avatar widget
import 'package:flutter/material.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/optimized_image.dart';

/// Animated avatar widget
/// Avatar with fade-in animation and pulse effect
class AnimatedAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showPulse;
  /// When false, skip enter/pulse and paint at rest (PERF-SCR-PCWEL-001).
  final bool animate;

  const AnimatedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 64.0,
    this.showPulse = false,
    this.animate = true,
  });

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (!widget.animate) {
      _controller.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AnimatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.showPulse != widget.showPulse) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    final reduceMotion = !AppAnimations.animationsEnabled(context);
    if (!widget.animate || reduceMotion) {
      _controller.stop();
      _controller.value = 1;
      return;
    }
    if (widget.showPulse) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
      return;
    }
    if (_controller.value < 1 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final placeholderColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: placeholderColor,
          ),
          child: ClipOval(
            child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                ? OptimizedImage(
                    imageUrl: widget.imageUrl!,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: placeholderColor,
                    child: Center(
                      child: Text(
                        widget.name != null && widget.name!.isNotEmpty
                            ? widget.name![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: widget.size * 0.4,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
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
