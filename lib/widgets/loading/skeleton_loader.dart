// Widget: SkeletonLoader
// Skeleton loading animation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import 'shimmer_effect.dart';

/// Skeleton loader widget
/// Displays skeleton placeholders while content loads
class SkeletonLoader extends ConsumerWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const SkeletonLoader({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final highlightColor = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight;

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
