// Widget: ImageIndicatorDots
// Image carousel indicator dots
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';

/// Image indicator dots widget
/// Displays dots to indicate current image in carousel
class ImageIndicatorDots extends ConsumerWidget {
  final int currentIndex;
  final int totalCount;
  final double dotSize;
  final double activeDotSize;
  final Color? activeColor;
  final Color? inactiveColor;

  const ImageIndicatorDots({
    Key? key,
    required this.currentIndex,
    required this.totalCount,
    this.dotSize = 6.0,
    this.activeDotSize = 8.0,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColorValue = activeColor ?? Colors.white;
    final inactiveColorValue = inactiveColor ?? Colors.white.withOpacity(0.4);

    if (totalCount <= 1) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalCount, (index) {
        final isActive = index == currentIndex;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? activeDotSize : dotSize,
          height: isActive ? activeDotSize : dotSize,
          decoration: BoxDecoration(
            color: isActive ? activeColorValue : inactiveColorValue,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
