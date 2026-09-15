import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../widgets/cards/swipeable_card.dart';
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
    if (AppAnimations.animationsEnabled(context) &&
        _entryController.value == 0) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = SwipeableCard.fitSize(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );
        final nameW = (cardSize.width * 0.44).clamp(100.0, 150.0);
        final subW = (cardSize.width * 0.29).clamp(72.0, 100.0);
        final nameH = AppTypography.h2.fontSize ?? 18;
        final subH = AppTypography.body.fontSize ?? 14;

        Widget card = SizedBox(
          width: cardSize.width,
          height: cardSize.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(SwipeableCard.cardRadius),
                  highlightColorOverride: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.lgbtGradient[4].withValues(alpha: 0.12),
                ),
                Positioned(
                  left: AppSpacing.spacingLG,
                  right: AppSpacing.spacingLG,
                  bottom: AppSpacing.spacingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonLoader(
                        width: nameW,
                        height: nameH,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                      const SizedBox(height: AppSpacing.spacingSM),
                      SkeletonLoader(
                        width: subW,
                        height: subH,
                        borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        if (!AppAnimations.animationsEnabled(context)) {
          return Center(child: card);
        }

        return FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Center(child: card),
          ),
        );
      },
    );
  }
}
