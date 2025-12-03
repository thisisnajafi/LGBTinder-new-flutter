// Widget: BottomSheetCustom
// Custom bottom sheet
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Custom bottom sheet widget
/// Styled bottom sheet with rounded corners and drag handle
class BottomSheetCustom extends ConsumerWidget {
  final Widget child;
  final String? title;
  final bool isDismissible;
  final bool enableDrag;

  const BottomSheetCustom({
    Key? key,
    required this.child,
    this.title,
    this.isDismissible = true,
    this.enableDrag = true,
  }) : super(key: key);

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetCustom(
        title: title,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.radiusLG),
          topRight: Radius.circular(AppRadius.radiusLG),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: AppSpacing.spacingMD),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            if (title != null) ...[
              Padding(
                padding: EdgeInsets.all(AppSpacing.spacingLG),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: textColor,
                      ),
                ),
              ),
            ],
            // Content
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
