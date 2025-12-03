// Loading states
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../widgets/animations/lottie_animations.dart';

/// Loading indicator widget
/// Displays a loading spinner with optional message
class LoadingIndicator extends ConsumerWidget {
  final String? message;

  const LoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLottieAnimations.loading(size: 48),
          if (message != null) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              message!,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
