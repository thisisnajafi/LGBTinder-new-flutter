import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_providers.dart';
import '../theme/app_colors.dart';
import '../theme/spacing_constants.dart' show AppSpacing;
import '../theme/typography.dart';

/// Subtle banner shown when serving stale/offline cached content.
class CachedContentBanner extends ConsumerWidget {
  const CachedContentBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(servingCachedContentProvider);
    if (!show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.surfaceElevatedDark.withValues(alpha: 0.95)
          : AppColors.accentPurple.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingXS,
          ),
          child: Text(
            'Showing cached content',
            style: AppTypography.labelMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
