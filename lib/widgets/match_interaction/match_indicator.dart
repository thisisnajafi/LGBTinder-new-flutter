// Widget: MatchIndicator
// Match percentage indicator
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Match indicator widget
/// Circular progress indicator showing match percentage
class MatchIndicator extends ConsumerWidget {
  final int matchPercentage;
  final double size;
  final double strokeWidth;
  final List<String>? matchReasons;

  const MatchIndicator({
    Key? key,
    required this.matchPercentage,
    this.size = 80.0,
    this.strokeWidth = 6.0,
    this.matchReasons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final percentage = matchPercentage.clamp(0, 100) / 100;

    Color getMatchColor() {
      if (matchPercentage >= 80) return AppColors.onlineGreen;
      if (matchPercentage >= 60) return AppColors.accentPurple;
      if (matchPercentage >= 40) return AppColors.warningYellow;
      return AppColors.notificationRed;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: strokeWidth,
                  backgroundColor: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
                  valueColor: AlwaysStoppedAnimation<Color>(getMatchColor()),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$matchPercentage%',
                    style: AppTypography.h2.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Match',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (matchReasons != null && matchReasons!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.spacingMD),
          ...matchReasons!.take(3).map((reason) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacingXS),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: getMatchColor(),
                  ),
                  SizedBox(width: AppSpacing.spacingXS),
                  Text(
                    reason,
                    style: AppTypography.caption.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
