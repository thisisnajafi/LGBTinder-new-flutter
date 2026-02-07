// Widget: ShimmerEffect
// Shimmer loading effect
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/animation_constants.dart';

/// Shimmer loading effect widget
/// Creates a shimmer animation for loading states
class ShimmerEffect extends ConsumerStatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerEffect({
    Key? key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = AppAnimations.shimmerDuration,
  }) : super(key: key);

  @override
  ConsumerState<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends ConsumerState<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveEmphasized),
    );
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
    final baseColor = widget.baseColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final highlightColor = widget.highlightColor ??
        (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: [
                0.0,
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
