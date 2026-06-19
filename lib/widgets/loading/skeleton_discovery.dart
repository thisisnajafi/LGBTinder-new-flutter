import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import 'skeleton_loader.dart';

/// Animated skeleton loader for the discovery card stack.
class SkeletonDiscovery extends StatefulWidget {
  const SkeletonDiscovery({super.key});

  @override
  State<SkeletonDiscovery> createState() => _SkeletonDiscoveryState();
}

class _SkeletonDiscoveryState extends State<SkeletonDiscovery>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curve = CurvedAnimation(
      parent: _entryController,
      curve: AppAnimations.curveDefault,
    );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.animationsEnabled(context) && _entryController.value == 0) {
      _entryController.forward();
    } else if (!AppAnimations.animationsEnabled(context)) {
      _entryController.value = 1;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252528) : AppColors.backgroundLight;

    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340, maxHeight: 520),
                margin: const EdgeInsets.all(AppSpacing.spacingLG),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusXL),
                  border: isDark
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.radiusXL),
                          topRight: Radius.circular(AppRadius.radiusXL),
                        ),
                        highlightColorOverride: isDark
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.lgbtGradient[4].withValues(alpha: 0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacingLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 150,
                            height: 20,
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusSM),
                          ),
                          const SizedBox(height: AppSpacing.spacingSM),
                          SkeletonLoader(
                            width: 100,
                            height: 16,
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusSM),
                          ),
                          const SizedBox(height: AppSpacing.spacingMD),
                          SkeletonLoader(
                            width: double.infinity,
                            height: 14,
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusSM),
                          ),
                          const SizedBox(height: AppSpacing.spacingSM),
                          SkeletonLoader(
                            width: 200,
                            height: 14,
                            borderRadius:
                                BorderRadius.circular(AppRadius.radiusSM),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spacingLG),
              _PulsingDots(color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.spacingMD),
              Text(
                'Finding your perfect matches...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots({required this.color});

  final Color color;

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.animationsEnabled(context) && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!AppAnimations.animationsEnabled(context)) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_controller.value + index * 0.2) % 1.0;
            final opacity = (0.35 + (phase < 0.5 ? phase : 1 - phase) * 1.3)
                .clamp(0.35, 1.0);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
