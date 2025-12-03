// Widget: AnimatedButton
// Animated button with effects
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Animated button widget
/// Button with scale animation and ripple effect
class AnimatedButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool useGradient;
  final bool isFullWidth;

  const AnimatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.useGradient = false,
    this.isFullWidth = true,
  }) : super(key: key);

  @override
  ConsumerState<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends ConsumerState<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? AppColors.accentPurple;
    final textColor = widget.textColor ?? Colors.white;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : _handleTapDown,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: isDisabled ? null : _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingXL,
            vertical: AppSpacing.spacingMD,
          ),
          decoration: BoxDecoration(
            gradient: widget.useGradient && !isDisabled
                ? AppTheme.accentGradient
                : null,
            color: widget.useGradient
                ? null
                : (isDisabled ? bgColor.withOpacity(0.5) : bgColor),
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: bgColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: textColor,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.spacingSM),
                    ],
                    Text(
                      widget.text,
                      style: AppTypography.button.copyWith(color: textColor),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
