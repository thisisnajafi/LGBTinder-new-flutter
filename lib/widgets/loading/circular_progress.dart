// Widget: CircularProgress
// Circular progress indicator
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Circular progress indicator widget
/// Custom styled loading spinner
class CircularProgress extends ConsumerWidget {
  final double? size;
  final Color? color;
  final double? strokeWidth;

  const CircularProgress({
    Key? key,
    this.size,
    this.color,
    this.strokeWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressColor = color ?? AppColors.accentPurple;
    final progressSize = size ?? 24.0;
    final progressStrokeWidth = strokeWidth ?? 3.0;

    return SizedBox(
      width: progressSize,
      height: progressSize,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        strokeWidth: progressStrokeWidth,
      ),
    );
  }
}
