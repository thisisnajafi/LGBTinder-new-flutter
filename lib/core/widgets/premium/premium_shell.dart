import 'package:flutter/material.dart';

import '../../constants/animation_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/border_radius_constants.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import '../app_page_header.dart';

/// Glass card shell — source of truth for premium surfaces across the app.
class PremiumShell extends StatelessWidget {
  const PremiumShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.spacingLG),
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppPageHeader.horizontalPadding,
    ),
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusXL),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.cardBackgroundLight,
              borderRadius: BorderRadius.circular(AppRadius.radiusXL),
              border: Border.all(
                color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Back-compat alias used by own-profile sections.
typedef PremiumProfileShell = PremiumShell;

class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.onEdit,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 36,
          margin: const EdgeInsets.only(right: AppSpacing.spacingSM, top: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: AppColors.brandGradient,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.accentPink,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit $title',
            icon: AppSvgIcon(
              assetPath: AppIcons.edit2,
              size: 20,
              color: AppColors.accentViolet,
            ),
          ),
      ],
    );
  }
}

/// Tap scale micro-interaction for premium cards.
class PremiumTapScale extends StatefulWidget {
  const PremiumTapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  State<PremiumTapScale> createState() => _PremiumTapScaleState();
}

class _PremiumTapScaleState extends State<PremiumTapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale =
        _pressed && AppAnimations.animationsEnabled(context) ? 0.97 : 1.0;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
