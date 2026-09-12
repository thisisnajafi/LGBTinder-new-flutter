import 'dart:ui';

import 'package:flutter/material.dart';

import '../../constants/animation_constants.dart';
import '../../theme/border_radius_constants.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import '../../responsive/responsive.dart';

/// Frosted lock overlay for tier-gated profile sections (basid / below min).
///
/// When [locked] is false, [child] is returned unchanged.
/// Reduce Motion skips the blur and uses a static dim only.
class ProfileLockedOverlay extends StatelessWidget {
  const ProfileLockedOverlay({
    super.key,
    required this.locked,
    required this.child,
    this.onUnlock,
    this.label = 'Upgrade',
    this.semanticLabel,
    this.borderRadius,
    this.compact = false,
  });

  static const overlayKey = ValueKey<String>('profileLockedOverlay');
  static const lockIconKey = ValueKey<String>('profileLockedLockIcon');

  final bool locked;
  final Widget child;
  final VoidCallback? onUnlock;
  final String label;
  final String? semanticLabel;
  final BorderRadius? borderRadius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.radiusMD);
    final reduceMotion = !AppAnimations.animationsEnabled(context);
    final dim = theme.colorScheme.surface.withValues(alpha: 0.62);

    Widget veil = ColoredBox(color: dim);
    if (!reduceMotion) {
      veil = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: veil,
      );
    }

    final lockColor = theme.colorScheme.onSurface.withValues(alpha: 0.88);
    final badge = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgIcon(
          key: lockIconKey,
          assetPath: AppIcons.lockOutline,
          size: compact ? 18 : 20,
          color: lockColor,
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.spacingXS),
          AppText(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );

    final layer = Stack(
      fit: StackFit.expand,
      children: [
        veil,
        Center(child: badge),
      ],
    );

    final overlay = onUnlock == null
        ? IgnorePointer(child: layer)
        : Semantics(
            button: true,
            label: semanticLabel ?? 'Locked. Upgrade to unlock.',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onUnlock,
                child: layer,
              ),
            ),
          );

    return ClipRRect(
      key: overlayKey,
      borderRadius: radius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(child: child),
          Positioned.fill(child: overlay),
        ],
      ),
    );
  }
}
