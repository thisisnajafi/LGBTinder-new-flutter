import 'package:flutter/material.dart';

import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    this.onAdjustFilters,
  });

  final VoidCallback? onAdjustFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(
            assetPath: AppIcons.search,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          Text(
            "You've seen everyone nearby",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Check back soon or expand your filters to see more people',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacingLG),
          Semantics(
            button: true,
            label: 'Adjust filters',
            child: OutlinedButton(
              onPressed: onAdjustFilters,
              child: const Text('Adjust Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
