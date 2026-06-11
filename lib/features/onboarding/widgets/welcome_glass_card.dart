import 'package:flutter/material.dart';

import '../../../core/theme/border_radius_constants.dart';
import '../../../core/theme/spacing_constants.dart';

/// Frosted glass container for welcome-screen taglines and short copy.
class WelcomeGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool onGradient;

  const WelcomeGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final frostedOnGradient = onGradient || isDark;

    return Container(
      width: double.infinity,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingLG,
            vertical: AppSpacing.spacingMD,
          ),
      decoration: BoxDecoration(
        color: frostedOnGradient
            ? Colors.white.withValues(alpha: 0.14)
            : colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.radiusXL),
        border: Border.all(
          color: frostedOnGradient
              ? Colors.white.withValues(alpha: 0.28)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: frostedOnGradient
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
