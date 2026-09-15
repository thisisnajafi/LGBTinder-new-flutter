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
import '../../core/responsive/responsive.dart';

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

  static final LinearGradient _accentGradient = AppTheme.accentGradient;
  static final LinearGradient _disabledAccent = LinearGradient(
    colors: [
      AppColors.accentPurple.withValues(alpha: 0.5),
      AppColors.accentGradientEnd.withValues(alpha: 0.5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static final LinearGradient _disabledPride = LinearGradient(
    colors: AppColors.lgbtGradient
        .map((c) => c.withValues(alpha: 0.5))
        .toList(growable: false),
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static final LinearGradient _sheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.center,
    colors: [
      Colors.white.withValues(alpha: 0.16),
      Colors.white.withValues(alpha: 0),
    ],
  );
  static final List<BoxShadow> _prideShadows = [
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
  static final List<BoxShadow> _accentShadows = [
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.tapDuration,
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: AppAnimations.buttonPressScale).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppAnimations.curveDefault,
          ),
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
    if (AppAnimations.animationsEnabled(context)) _controller.reverse();
  }

  void _handleTapCancel() {
    if (AppAnimations.animationsEnabled(context)) _controller.reverse();
  }

  void _handleTap() {
    AppHaptics.light();
    widget.onPressed?.call();
  }

  LinearGradient _gradient(bool isDisabled) {
    if (isDisabled) {
      return widget.usePrideGradient ? _disabledPride : _disabledAccent;
    }
    return widget.usePrideGradient ? AppColors.prideGradient : _accentGradient;
  }

  List<BoxShadow> _shadows() {
    return widget.usePrideGradient ? _prideShadows : _accentShadows;
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? 56.0;
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final animatePress =
        !isDisabled && AppAnimations.animationsEnabled(context);
    final borderRadius = BorderRadius.circular(AppRadius.radiusRound);

    Widget button = SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: buttonHeight,
      child: RepaintBoundary(
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
                  DecoratedBox(decoration: BoxDecoration(gradient: _sheen)),
                Padding(
                  padding:
                      widget.padding ??
                      EdgeInsets.symmetric(horizontal: AppSpacing.spacingXL),
                  child: widget.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.iconPath != null ||
                                widget.icon != null) ...[
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
                            Flexible(
                              child: AppText(
                                widget.text,
                                style: AppTypography.button.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  shadows: widget.usePrideGradient
                                      ? const [
                                          Shadow(
                                            color: Color(0x73000000),
                                            blurRadius: 6,
                                            offset: Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (animatePress) {
      button = ScaleTransition(scale: _scaleAnimation, child: button);
    }

    return GestureDetector(
      onTapDown: animatePress ? _handleTapDown : null,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: animatePress ? _handleTapCancel : null,
      onTap: isDisabled ? null : _handleTap,
      child: button,
    );
  }
}
