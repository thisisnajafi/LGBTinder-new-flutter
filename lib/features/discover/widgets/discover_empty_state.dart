import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/utils/app_icons.dart';
import '../../../core/widgets/premium/premium_design_system.dart';
import '../../../widgets/buttons/gradient_button.dart';

/// Empty discover stack with premium styling and configurable actions.
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
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = !AppAnimations.animationsEnabled(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumPageHeader.horizontalPadding,
        ),
        child: PremiumShell(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(AppSpacing.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyIllustration(animate: !reduceMotion),
              const SizedBox(height: AppSpacing.spacingXL),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingSM),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.spacingXL),
              if (onPrimaryAction != null)
                GradientButton(
                  text: primaryActionLabel,
                  iconPath: AppIcons.filter,
                  onPressed: onPrimaryAction,
                  isFullWidth: true,
                ),
              if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                const SizedBox(height: AppSpacing.spacingSM),
                PremiumTapScale(
                  onTap: onSecondaryAction!,
                  semanticLabel: secondaryActionLabel!,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      border: Border.all(
                        color: AppColors.accentViolet.withValues(alpha: 0.35),
                      ),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.accentViolet.withValues(alpha: 0.06),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcon(
                          assetPath: AppIcons.location,
                          size: 18,
                          color: AppColors.accentViolet,
                        ),
                        const SizedBox(width: AppSpacing.spacingSM),
                        Text(
                          secondaryActionLabel!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.accentViolet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (tertiaryActionLabel != null && onTertiaryAction != null) ...[
                const SizedBox(height: AppSpacing.spacingSM),
                PremiumTapScale(
                  onTap: onTertiaryAction!,
                  semanticLabel: tertiaryActionLabel!,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.spacingXS,
                    ),
                    child: Text(
                      tertiaryActionLabel!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.accentRose,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatefulWidget {
  const _EmptyIllustration({required this.animate});

  final bool animate;

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
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = widget.animate ? 0.96 + (_pulse.value * 0.06) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 104,
        height: 104,
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
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: AppIcons.search,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
