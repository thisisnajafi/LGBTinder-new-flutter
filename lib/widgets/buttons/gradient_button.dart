// Widget: GradientButton
// Primary CTA — accent or pride gradient with shared polish app-wide.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/constants/animation_constants.dart';

/// Gradient button widget — primary CTA with accent or pride gradient.
class GradientButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;
  final EdgeInsets? padding;
  final IconData? icon; // Legacy support
  final String? iconPath; // SVG icon path
  final bool isFullWidth;
  /// When true, use pride/LGBT gradient instead of accent purple. Use on 1–2 key CTAs.
  final bool usePrideGradient;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height,
    this.padding,
    this.icon,
    this.iconPath,
    this.isFullWidth = true,
    this.usePrideGradient = false,
  });

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
      duration: AppAnimations.tapDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.buttonPressScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveDefault),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (AppAnimations.animationsEnabled(context)) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    AppHaptics.light();
    widget.onPressed?.call();
  }

  LinearGradient _gradient(bool isDisabled) {
    if (isDisabled) {
      final base = widget.usePrideGradient
          ? AppColors.lgbtGradient
          : [AppColors.accentPurple, AppColors.accentGradientEnd];
      return LinearGradient(
        colors: base.map((c) => c.withValues(alpha: 0.5)).toList(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return widget.usePrideGradient
        ? AppColors.prideGradient
        : AppTheme.accentGradient;
  }

  TextStyle _labelStyle() {
    final base = AppTypography.button.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    if (!widget.usePrideGradient) return base;
    return base.copyWith(
      fontWeight: FontWeight.w800,
      shadows: const [
        Shadow(
          color: Color(0x8C000000),
          blurRadius: 8,
          offset: Offset(0, 1.5),
        ),
        Shadow(
          color: Color(0x59000000),
          blurRadius: 14,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildLabelContent() {
    if (widget.isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    final labelStyle = _labelStyle();
    final row = Row(
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
          style: labelStyle,
        ),
      ],
    );

    if (!widget.usePrideGradient) return row;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingLG,
          vertical: AppSpacing.spacingSM,
        ),
        child: row,
      ),
    );
  }

  List<BoxShadow> _shadows() {
    if (widget.usePrideGradient) {
      return [
        BoxShadow(
          color: AppColors.accentRose.withValues(alpha: 0.45),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.accentPurple.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: AppColors.accentGradientEnd.withValues(alpha: 0.38),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: AppColors.accentPurple.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? 56.0;
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final borderRadius = BorderRadius.circular(AppRadius.radiusRound);

    return GestureDetector(
      onTapDown: isDisabled ? null : _handleTapDown,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: isDisabled ? null : _handleTapCancel,
      onTap: isDisabled ? null : _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          height: buttonHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: _gradient(isDisabled),
              border: isDisabled
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.38),
                      width: 1.5,
                    ),
              boxShadow: isDisabled ? null : _shadows(),
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isDisabled)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: widget.padding ??
                        EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacingXL,
                        ),
                    child: Center(child: _buildLabelContent()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
