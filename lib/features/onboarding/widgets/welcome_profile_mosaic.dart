import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

/// Decorative profile-photo mosaic for the welcome screen hero.
/// Uses gradient tiles (no network images) with staggered entrance animation.
class WelcomeProfileMosaic extends StatefulWidget {
  final double maxHeight;

  const WelcomeProfileMosaic({
    super.key,
    this.maxHeight = 220,
  });

  @override
  State<WelcomeProfileMosaic> createState() => _WelcomeProfileMosaicState();
}

class _WelcomeProfileMosaicState extends State<WelcomeProfileMosaic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static final List<LinearGradient> _tileGradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.accentRose, AppColors.accentPink],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.accentGradientStart, AppColors.accentPurple],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.lgbtGradient[4], AppColors.lgbtGradient[3]],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.lgbtGradient[2], AppColors.lgbtGradient[1]],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.lgbtGradient[5], AppColors.accentPurple],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.lgbtGradient[0], AppColors.lgbtGradient[1]],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.lgbtGradient[3], AppColors.lgbtGradient[4]],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.accentPink, AppColors.accentPurple],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppAnimations.animationsEnabled(context)) {
        _controller.forward();
      } else {
        _controller.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = !AppAnimations.animationsEnabled(context);

    return Semantics(
      label: 'Community profile preview collage',
      child: SizedBox(
        height: widget.maxHeight,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = AppSpacing.spacingSM;
            final colWidth = (constraints.maxWidth - gap * 2) / 3;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MosaicColumn(
                  controller: _controller,
                  disableAnimations: disableAnimations,
                  startIndex: 0,
                  tileCount: 2,
                  width: colWidth,
                  gap: gap,
                  heights: [0.58, 0.38],
                  gradients: _tileGradients,
                ),
                SizedBox(width: gap),
                _MosaicColumn(
                  controller: _controller,
                  disableAnimations: disableAnimations,
                  startIndex: 2,
                  tileCount: 3,
                  width: colWidth,
                  gap: gap,
                  heights: [0.32, 0.36, 0.28],
                  gradients: _tileGradients,
                ),
                SizedBox(width: gap),
                _MosaicColumn(
                  controller: _controller,
                  disableAnimations: disableAnimations,
                  startIndex: 5,
                  tileCount: 3,
                  width: colWidth,
                  gap: gap,
                  heights: [0.4, 0.34, 0.22],
                  gradients: _tileGradients,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MosaicColumn extends StatelessWidget {
  final AnimationController controller;
  final bool disableAnimations;
  final int startIndex;
  final int tileCount;
  final double width;
  final double gap;
  final List<double> heights;
  final List<LinearGradient> gradients;

  const _MosaicColumn({
    required this.controller,
    required this.disableAnimations,
    required this.startIndex,
    required this.tileCount,
    required this.width,
    required this.gap,
    required this.heights,
    required this.gradients,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: List.generate(tileCount, (i) {
          final globalIndex = startIndex + i;
          final flex = (heights[i] * 100).round().clamp(1, 100);
          final animation = disableAnimations
              ? AlwaysStoppedAnimation(1.0)
              : CurvedAnimation(
                  parent: controller,
                  curve: Interval(
                    (globalIndex * 0.08).clamp(0.0, 0.72),
                    (0.35 + globalIndex * 0.08).clamp(0.35, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                );

          return Expanded(
            flex: flex,
            child: Padding(
              padding: EdgeInsets.only(bottom: i < tileCount - 1 ? gap : 0),
              child: _MosaicTile(
                animation: animation,
                gradient: gradients[globalIndex % gradients.length],
                showIcon: globalIndex.isEven,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MosaicTile extends StatelessWidget {
  final Animation<double> animation;
  final LinearGradient gradient;
  final bool showIcon;

  const _MosaicTile({
    required this.animation,
    required this.gradient,
    required this.showIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: 0.88 + (animation.value * 0.12),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.radiusSM),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
              blurRadius: isDark ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: showIcon
            ? Center(
                child: AppSvgIcon(
                  assetPath: AppIcons.userOutline,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
            : null,
      ),
    );
  }
}
