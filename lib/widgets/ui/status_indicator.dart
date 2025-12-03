// Widget: StatusIndicator
// Online/offline status indicator
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';

/// Status indicator widget
/// Displays online/offline status with text and color
class StatusIndicator extends ConsumerWidget {
  final bool isOnline;
  final String? customText;
  final double size;

  const StatusIndicator({
    Key? key,
    required this.isOnline,
    this.customText,
    this.size = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final statusColor = isOnline ? AppColors.onlineGreen : secondaryTextColor;
    final statusText = customText ?? (isOnline ? 'Online' : 'Offline');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              width: 2,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.spacingXS),
        Text(
          statusText,
          style: AppTypography.caption.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
