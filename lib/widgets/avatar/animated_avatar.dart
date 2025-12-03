// Widget: AnimatedAvatar
// Animated avatar widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../images/optimized_image.dart';

/// Animated avatar widget
/// Avatar with fade-in animation and pulse effect
class AnimatedAvatar extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showPulse;

  const AnimatedAvatar({
    Key? key,
    this.imageUrl,
    this.name,
    this.size = 64.0,
    this.showPulse = false,
  }) : super(key: key);

  @override
  ConsumerState<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends ConsumerState<AnimatedAvatar>
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
    _controller.forward();

    if (widget.showPulse) {
      _controller.repeat(reverse: true);
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
