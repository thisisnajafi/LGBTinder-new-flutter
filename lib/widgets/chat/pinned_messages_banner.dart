// Widget: PinnedMessagesBanner
// Banner for pinned messages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Pinned messages banner widget
/// Displays banner showing pinned messages count with tap to scroll
class PinnedMessagesBanner extends ConsumerWidget {
  final int pinnedCount;
  final VoidCallback? onTap;

  const PinnedMessagesBanner({
    Key? key,
    required this.pinnedCount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pinnedCount <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin,
              size: 16,
              color: AppColors.accentPurple,
            ),
            SizedBox(width: AppSpacing.spacingSM),
            Text(
              '$pinnedCount pinned message${pinnedCount > 1 ? 's' : ''}',
              style: AppTypography.caption.copyWith(color: textColor),
            ),
            SizedBox(width: AppSpacing.spacingSM),
            Icon(
              Icons.arrow_downward,
              size: 16,
              color: AppColors.accentPurple,
            ),
          ],
        ),
      ),
    );
  }
}
