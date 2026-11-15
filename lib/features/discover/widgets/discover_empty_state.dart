import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../widgets/buttons/gradient_button.dart';

/// Empty discover stack with premium styling and configurable actions.
///
/// Up to three actions: a filled primary button, an outlined secondary
/// button and a text tertiary action. Each is at least 48 dp tall. The card
/// scrolls when it does not fit (small screens, large text).
class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    this.title = "You've seen everyone nearby",
    this.subtitle =
        'Check back soon or expand your filters to see more people',
    this.iconPath,
    this.primaryActionLabel = 'Adjust filters',
    this.primaryActionIconPath,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIconPath,
    this.onSecondaryAction,
    this.tertiaryActionLabel,
    this.onTertiaryAction,
  });

  @visibleForTesting
  static const Key primaryActionKey = ValueKey('discover-empty-primary');
  @visibleForTesting
  static const Key secondaryActionKey = ValueKey('discover-empty-secondary');
  @visibleForTesting
  static const Key tertiaryActionKey = ValueKey('discover-empty-tertiary');

  final String title;
  final String subtitle;
  final String? iconPath;
  final String primaryActionLabel;

  /// Icon of the primary button. Defaults to the filter icon, which fits
  /// the default "Adjust filters" label; pass one that matches the action.
  final String? primaryActionIconPath;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;

  /// Icon of the secondary button. Defaults to the location icon.
  final String? secondaryActionIconPath;
  final VoidCallback? onSecondaryAction;
  final String? tertiaryActionLabel;
  final VoidCallback? onTertiaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = !AppAnimations.animationsEnabled(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final dense = constraints.maxHeight < 640 ||
            constraints.maxWidth < AppBreakpoints.compact ||
            textScale > 1.15;
        final gap = dense ? AppSpacing.spacingMD : AppSpacing.spacingXL;
        final minHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: PremiumPageHeader.horizontalPadding,
            vertical: AppSpacing.spacingSM,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: ResponsiveGrid.constrained(
                context,
                PremiumShell(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.all(
                    dense ? AppSpacing.spacingMD : AppSpacing.spacingXL,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EmptyIllustration(
                        animate: !reduceMotion,
                        iconPath: iconPath ?? AppIcons.search,
                        dense: dense,
                      ),
                      SizedBox(height: gap),
                      AppText(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.spacingSM),
                      AppText(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.58),
                          height: 1.45,
                        ),
                        maxLines: 4,
                      ),
                      SizedBox(height: gap),
                      if (onPrimaryAction != null)
                        GradientButton(
                          key: primaryActionKey,
                          text: primaryActionLabel,
                          iconPath: primaryActionIconPath ?? AppIcons.filter,
                          onPressed: onPrimaryAction,
                          isFullWidth: true,
                        ),
                      if (secondaryActionLabel != null &&
                          onSecondaryAction != null) ...[
                        const SizedBox(height: AppSpacing.spacingSM),
                        PremiumTapScale(
                          key: secondaryActionKey,
                          onTap: onSecondaryAction!,
                          semanticLabel: secondaryActionLabel!,
                          // The label is already announced by the button;
                          // without this it was read twice.
                          child: ExcludeSemantics(
                            child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacingMD,
                              vertical: AppSpacing.spacingSM,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusRound,
                              ),
                              border: Border.all(
                                color: AppColors.accentViolet
                                    .withValues(alpha: 0.35),
                              ),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : AppColors.accentViolet
                                      .withValues(alpha: 0.06),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppSvgIcon(
                                  assetPath: secondaryActionIconPath ??
                                      AppIcons.location,
                                  size: 18,
                                  color: AppColors.accentViolet,
                                ),
                                const SizedBox(width: AppSpacing.spacingSM),
                                Flexible(
                                  child: AppText(
                                    secondaryActionLabel!,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: AppColors.accentViolet,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        ),
                      ],
                      if (tertiaryActionLabel != null &&
                          onTertiaryAction != null) ...[
                        const SizedBox(height: AppSpacing.spacingSM),
                        PremiumTapScale(
                          key: tertiaryActionKey,
                          onTap: onTertiaryAction!,
                          semanticLabel: tertiaryActionLabel!,
                          child: ExcludeSemantics(
                            child: Container(
                            width: double.infinity,
                            // Text-only action, but still a full 48 dp target.
                            constraints: const BoxConstraints(minHeight: 48),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.spacingXS,
                            ),
                            child: AppText(
                              tertiaryActionLabel!,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.accentRose,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyIllustration extends StatefulWidget {
  const _EmptyIllustration({
    required this.animate,
    required this.iconPath,
    required this.dense,
  });

  final bool animate;
  final String iconPath;
  final bool dense;

  @override
  State<_EmptyIllustration> createState() => _EmptyIllustrationState();
}

class _EmptyIllustrationState extends State<_EmptyIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The pulse runs for as long as the empty state is on screen. The
    // boundaries keep it to a transform on an already painted layer, and
    // keep the text and buttons around it from repainting with it.
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = widget.animate ? 0.96 + (_pulse.value * 0.06) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: RepaintBoundary(
        child: Container(
        width: widget.dense ? 72 : 104,
        height: widget.dense ? 72 : 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentViolet.withValues(alpha: 0.16),
              AppColors.accentRose.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(
            color: AppColors.accentViolet.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentViolet.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: widget.dense ? 44 : 60,
            height: widget.dense ? 44 : 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: widget.iconPath,
                size: widget.dense ? 22 : 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}
