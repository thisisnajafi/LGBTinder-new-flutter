// Widget: GradientButton
// Gradient button
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';

/// Gradient button widget
/// Primary CTA button with accent gradient
class GradientButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final EdgeInsets? padding;
  final IconData? icon; // Legacy support
  final String? iconPath; // SVG icon path
  final bool isFullWidth;

  const GradientButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height,
    this.padding,
    this.icon,
    this.iconPath,
    this.isFullWidth = true,
  }) : super(key: key);

  @override
  ConsumerState<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends ConsumerState<GradientButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonHeight = widget.height ?? 56.0;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : _handleTapDown,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: isDisabled ? null : _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          height: buttonHeight,
          padding: widget.padding ?? EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingXL,
          ),
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [
                      AppColors.accentPurple.withOpacity(0.5),
                      AppColors.accentGradientEnd.withOpacity(0.5),
                    ],
                  )
                : AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.accentPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.iconPath != null || widget.icon != null) ...[
                      widget.iconPath != null
                          ? AppSvgIcon(
                              assetPath: widget.iconPath!,
                              size: 20,
                              color: Colors.white,
                            )
                          : Icon(
                              widget.icon!,
                              color: Colors.white,
                              size: 20,
                            ),
                      SizedBox(width: AppSpacing.spacingSM),
                    ],
                    Text(
                      widget.text,
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
