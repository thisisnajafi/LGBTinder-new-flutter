import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/border_radius_constants.dart';
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
    final primary = theme.colorScheme.primary;
    final reduceMotion = !AppAnimations.animationsEnabled(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EmptyIllustration(
              primary: primary,
              animate: !reduceMotion,
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
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
              _ActionButton(
                label: primaryActionLabel,
                iconPath: AppIcons.filter,
                filled: true,
                onPressed: onPrimaryAction!,
              ),
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppSpacing.spacingSM),
              _ActionButton(
                label: secondaryActionLabel!,
                iconPath: AppIcons.location,
                filled: false,
                onPressed: onSecondaryAction!,
              ),
            ],
            if (tertiaryActionLabel != null && onTertiaryAction != null) ...[
              const SizedBox(height: AppSpacing.spacingXS),
              TextButton.icon(
                onPressed: onTertiaryAction,
                icon: AppSvgIcon(
                  assetPath: AppIcons.filter,
                  size: 18,
                  color: primary,
                ),
                label: Text(tertiaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyIllustration extends StatefulWidget {
  const _EmptyIllustration({
    required this.primary,
    required this.animate,
  });

  final Color primary;
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
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.primary.withValues(alpha: 0.18),
              AppColors.accentPink.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(
            color: widget.primary.withValues(alpha: 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Center(
              child: AppSvgIcon(
                assetPath: AppIcons.search,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.iconPath,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final String iconPath;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgIcon(
          assetPath: iconPath,
          size: 18,
          color: filled ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.spacingSM),
        Text(label),
      ],
    );

    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        child: filled
            ? FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                ),
                child: child,
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                  ),
                ),
                child: child,
              ),
      ),
    );
  }
}
