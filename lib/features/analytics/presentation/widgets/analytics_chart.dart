import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';

/// Analytics chart widget - displays data visualizations
class AnalyticsChart extends ConsumerWidget {
  final String title;
  final Map<String, int> data;
  final Color? barColor;
  final String? subtitle;
  final double height;

  const AnalyticsChart({
    Key? key,
    required this.title,
    required this.data,
    this.barColor,
    this.subtitle,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final chartColor = barColor ?? AppColors.primaryLight;

    if (data.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        ),
        child: Container(
          height: height,
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Center(
            child: Text(
              'No data available',
              style: AppTypography.bodyMedium.copyWith(color: subtitleColor),
            ),
          ),
        ),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(color: subtitleColor),
              ),
            ],

            SizedBox(height: AppSpacing.spacingMD),

            // Chart
            SizedBox(
              height: height - 80, // Account for title and padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((entry) {
                  final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        Text(
                          entry.value.toString(),
                          style: AppTypography.labelSmall.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),

                        // Bar
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: chartColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(AppRadius.radiusXS),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: percentage.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: chartColor,
                                  borderRadius: BorderRadius.circular(AppRadius.radiusXS),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),

                        // Label
                        Text(
                          _formatLabel(entry.key),
                          style: AppTypography.labelSmall.copyWith(color: subtitleColor),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLabel(String key) {
    // Format keys for display (e.g., convert camelCase to Title Case)
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word)
        .join(' ');
  }
}
