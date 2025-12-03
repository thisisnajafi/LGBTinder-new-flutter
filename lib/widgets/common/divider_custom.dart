// Widget: DividerCustom
// Custom divider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';

/// Custom divider widget
/// Styled divider with optional text and spacing
class DividerCustom extends ConsumerWidget {
  final String? text;
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  const DividerCustom({
    Key? key,
    this.text,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;
    final textColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (text != null) {
      return Row(
        children: [
          Expanded(
            child: Divider(
              height: height ?? 1,
              thickness: thickness ?? 1,
              color: borderColor,
              indent: indent,
              endIndent: AppSpacing.spacingMD,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingMD),
            child: Text(
              text!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              height: height ?? 1,
              thickness: thickness ?? 1,
              color: borderColor,
              indent: AppSpacing.spacingMD,
              endIndent: endIndent,
            ),
          ),
        ],
      );
    }

    return Divider(
      height: height ?? 1,
      thickness: thickness ?? 1,
      color: borderColor,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
