import 'package:flutter/material.dart';

import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';

/// Empty discover stack with configurable actions for filters, distance, and location.
class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    this.title = "You've seen everyone nearby",
    this.subtitle =
        'Check back soon or expand your filters to see more people',
    this.primaryActionLabel = 'Adjust filters',
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.tertiaryActionLabel,
    this.onTertiaryAction,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? tertiaryActionLabel;
  final VoidCallback? onTertiaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingXL),
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
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingLG),
            if (onPrimaryAction != null)
              Semantics(
                button: true,
                label: primaryActionLabel,
                child: FilledButton(
                  onPressed: onPrimaryAction,
                  child: Text(primaryActionLabel),
                ),
              ),
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppSpacing.spacingSM),
              Semantics(
                button: true,
                label: secondaryActionLabel,
                child: OutlinedButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
              ),
            ],
            if (tertiaryActionLabel != null && onTertiaryAction != null) ...[
              const SizedBox(height: AppSpacing.spacingSM),
              Semantics(
                button: true,
                label: tertiaryActionLabel,
                child: TextButton(
                  onPressed: onTertiaryAction,
                  child: Text(tertiaryActionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
