import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';

/// Compact premium bar showing active discovery filters on the Discover tab.
class DiscoverActiveFiltersBar extends StatelessWidget {
  const DiscoverActiveFiltersBar({
    super.key,
    required this.labels,
    required this.onEdit,
    required this.onClear,
  });

  final List<String> labels;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PremiumPageHeader.horizontalPadding,
        0,
        PremiumPageHeader.horizontalPadding,
        AppSpacing.spacingSM,
      ),
      child: PremiumShell(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentViolet.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: AppIcons.filter,
                      size: 16,
                      color: AppColors.accentViolet,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingSM),
                Expanded(
                  child: Text(
                    'Active filters',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PremiumTapScale(
                  onTap: onClear,
                  semanticLabel: 'Clear all filters',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingXS,
                      vertical: AppSpacing.spacingXS,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.close,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacingXS),
                PremiumTapScale(
                  onTap: onEdit,
                  semanticLabel: 'Edit filters',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacingMD,
                      vertical: AppSpacing.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: AppColors.brandGradient,
                    ),
                    child: Text(
                      'Edit',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.spacingXS),
                    _DiscoverFilterChip(label: labels[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverFilterChip extends StatelessWidget {
  const _DiscoverFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: AppColors.accentViolet.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.accentViolet,
        ),
      ),
    );
  }
}
