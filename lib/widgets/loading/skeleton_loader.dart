// Widget: SkeletonLoader
// Skeleton loading animation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'shimmer_effect.dart';

/// Dark mode base color — visibly lighter than black so skeleton is readable
const Color _skeletonBaseDark = Color(0xFF252528);

/// Skeleton loader widget
/// Displays skeleton placeholders while content loads
class SkeletonLoader extends ConsumerWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;
  /// Optional override for shimmer highlight (e.g. soft pride tint on discovery).
  final Color? highlightColorOverride;

  const SkeletonLoader({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
    this.highlightColorOverride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Dark: use a visibly lighter gray so skeleton is clear on black/near-black background
    final baseColor = isDark ? _skeletonBaseDark : AppColors.surfaceLight;
    final highlightColor = highlightColorOverride ??
        (isDark
            ? Colors.white.withOpacity(0.2)
            : AppColors.surfaceElevatedLight);

    return ShimmerEffect(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.radiusSM),
        ),
        child: child,
      ),
    );
  }
}
