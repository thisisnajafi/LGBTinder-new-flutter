// Loading states — lightweight Material spinner (no Lottie on critical paths).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart';

/// Loading indicator with optional message. Uses [CircularProgressIndicator] only.
class LoadingIndicator extends ConsumerWidget {
  final String? message;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: disableAnimations
                ? Icon(
                    Icons.hourglass_empty,
                    size: size * 0.6,
                    color: AppColors.accentPurple,
                  )
                : CircularProgressIndicator(
                    color: AppColors.accentPurple,
                    strokeWidth: 3,
                  ),
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.spacingMD),
            Text(
              message!,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
