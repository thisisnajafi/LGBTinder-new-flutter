import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../core/responsive/responsive.dart';

/// Compact premium bar showing active discovery filters on the Discover tab.
class DiscoverActiveFiltersBar extends StatefulWidget {
  const DiscoverActiveFiltersBar({
    super.key,
    required this.labels,
    required this.onEdit,
    required this.onClear,
  });

  static const Key barKey = ValueKey('discover-active-filters-bar');

  final List<String> labels;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  State<DiscoverActiveFiltersBar> createState() =>
      _DiscoverActiveFiltersBarState();
}

class _DiscoverActiveFiltersBarState extends State<DiscoverActiveFiltersBar> {
  List<String> _displayed = const [];

  @override
  void initState() {
    super.initState();
    _displayed = widget.labels;
  }

  @override
  void didUpdateWidget(covariant DiscoverActiveFiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.labels.isNotEmpty) {
      _displayed = widget.labels;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBar = widget.labels.isNotEmpty;
    final duration = AppAnimations.animationsEnabled(context)
        ? AppAnimations.transitionModal
        : Duration.zero;

    return ClipRect(
      child: AnimatedAlign(
        key: DiscoverActiveFiltersBar.barKey,
        duration: duration,
        curve: AppAnimations.curveDefault,
        alignment: Alignment.topCenter,
        heightFactor: showBar ? 1 : 0,
        child: IgnorePointer(
          ignoring: !showBar,
          child: _displayed.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 320;
                            final titleRow = Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentViolet
                                        .withValues(alpha: 0.12),
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
                                  child: AppText(
                                    'Active filters',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            );
                            final actions = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PremiumTapScale(
                                  onTap: widget.onClear,
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
                                        const SizedBox(
                                          width: AppSpacing.spacingXS,
                                        ),
                                        AppText(
                                          'Clear',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.55),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.spacingXS),
                                PremiumTapScale(
                                  onTap: widget.onEdit,
                                  semanticLabel: 'Edit filters',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.spacingMD,
                                      vertical: AppSpacing.spacingXS,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.radiusRound,
                                      ),
                                      color: theme.colorScheme.primary,
                                    ),
                                    child: AppText(
                                      'Edit',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  titleRow,
                                  const SizedBox(height: AppSpacing.spacingSM),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: actions,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: titleRow),
                                actions,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.spacingSM),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < _displayed.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(width: AppSpacing.spacingXS),
                                _DiscoverFilterChip(label: _displayed[i]),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingMD,
        vertical: AppSpacing.spacingXS,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        color: AppColors.accentViolet.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.22),
        ),
      ),
      child: AppText(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.accentViolet,
        ),
        maxLines: 1,
      ),
    );
  }
}
