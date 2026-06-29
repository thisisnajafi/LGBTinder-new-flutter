import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/border_radius_constants.dart';
import '../theme/spacing_constants.dart';

/// Small age pill used on profile avatars and overlays.
enum ProfileAgeBadgeStyle {
  /// Sits on the bottom edge of a circular avatar.
  avatarOverlay,

  /// Compact pill for inline use next to a name.
  inline,

  /// Frosted pill on photo hero overlays.
  heroOverlay,

  /// Solid gradient pill on discovery-style photo cards.
  photoOverlay,
}

class ProfileAgeBadge extends StatelessWidget {
  const ProfileAgeBadge({
    super.key,
    required this.age,
    this.style = ProfileAgeBadgeStyle.avatarOverlay,
  });

  final int age;
  final ProfileAgeBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    switch (style) {
      case ProfileAgeBadgeStyle.avatarOverlay:
        return _AvatarOverlayBadge(age: age, primary: primary, theme: theme);
      case ProfileAgeBadgeStyle.inline:
        return _InlineBadge(age: age, primary: primary, theme: theme);
      case ProfileAgeBadgeStyle.heroOverlay:
        return _HeroOverlayBadge(age: age, theme: theme);
      case ProfileAgeBadgeStyle.photoOverlay:
        return _PhotoOverlayBadge(age: age, theme: theme);
    }
  }
}

class _AvatarOverlayBadge extends StatelessWidget {
  const _AvatarOverlayBadge({
    required this.age,
    required this.primary,
    required this.theme,
  });

  final int age;
  final Color primary;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: theme.colorScheme.surface,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          '$age',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({
    required this.age,
    required this.primary,
    required this.theme,
  });

  final int age;
  final Color primary;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingSM,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Text(
        '$age',
        style: theme.textTheme.labelMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroOverlayBadge extends StatelessWidget {
  const _HeroOverlayBadge({
    required this.age,
    required this.theme,
  });

  final int age;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 0.5,
        ),
      ),
      child: Text(
        '$age',
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PhotoOverlayBadge extends StatelessWidget {
  const _PhotoOverlayBadge({
    required this.age,
    required this.theme,
  });

  final int age;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppColors.accentRose.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingXS,
        ),
        child: Text(
          '$age',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            height: 1,
          ),
        ),
      ),
    );
  }
}
