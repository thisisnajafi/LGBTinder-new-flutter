// Widget: LoadingIndicator
// Loading indicator for matches
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../loading/circular_progress.dart';

/// Loading indicator widget for match interactions
/// Shows loading state during match operations
class LoadingIndicator extends ConsumerWidget {
  final String? message;
  final double size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgress(
            size: size,
            color: AppColors.accentPurple,
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
