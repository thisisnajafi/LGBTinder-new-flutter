import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/border_radius_constants.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import 'premium_shell.dart';

/// Single row inside a premium settings group.
class PremiumSettingsTile extends StatelessWidget {
  const PremiumSettingsTile({
    super.key,
    required this.iconPath,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.accent = AppColors.accentViolet,
    this.destructive = false,
  });

  final String iconPath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color accent;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = destructive ? AppColors.feedbackError : accent;
    final titleColor =
        destructive ? AppColors.feedbackError : theme.colorScheme.onSurface;

    return PremiumTapScale(
      onTap: onTap,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.12),
              ),
              child: Center(
                child: AppSvgIcon(assetPath: iconPath, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                AppSvgIcon(
                  assetPath: AppIcons.getIconPath('arrow-right-3'),
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
          ],
        ),
      ),
    );
  }
}

/// Grouped settings rows inside a glass shell.
class PremiumSettingsGroup extends StatelessWidget {
  const PremiumSettingsGroup({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.margin,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsets? margin;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PremiumShell(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PremiumSectionHeader(title: title, subtitle: subtitle),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          ...children,
        ],
      ),
    );
  }
}

/// Premium toggle row for settings detail screens.
class PremiumToggleRow extends StatelessWidget {
  const PremiumToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconPath,
    this.accent = AppColors.accentViolet,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? iconPath;
  final Color accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rowOpacity = enabled ? 1.0 : 0.55;

    return Opacity(
      opacity: rowOpacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
        padding: const EdgeInsets.all(AppSpacing.spacingMD),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardBackgroundDark
              : AppColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.12 : 0.1),
          ),
        ),
        child: Row(
          children: [
            if (iconPath != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: AppSvgIcon(assetPath: iconPath!, size: 18, color: accent),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: AppColors.accentPink,
            ),
          ],
        ),
      ),
    );
  }
}

/// Label + value row for subscription/account detail screens.
class PremiumInfoRow extends StatelessWidget {
  const PremiumInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    this.badgeColor,
  });

  final String label;
  final String value;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.accentPink).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                badge!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeColor ?? AppColors.accentPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selectable sound option with preview control.
class PremiumSoundOptionTile extends StatelessWidget {
  const PremiumSoundOptionTile({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelect,
    this.onPreview,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isSelected ? AppColors.accentPink : AppColors.accentViolet;

    return PremiumTapScale(
      onTap: onSelect ?? () {},
      semanticLabel: label,
      child: Opacity(
        opacity: onSelect == null ? 0.55 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardBackgroundDark
                : AppColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(AppRadius.radiusLG),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentPink.withValues(alpha: 0.35)
                  : AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
            ),
          ),
          child: Row(
            children: [
              AppSvgIcon(
                assetPath: isSelected
                    ? AppIcons.tickCircle
                    : AppIcons.getIconPath('record-circle'),
                size: 20,
                color: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isSelected)
                      Text(
                        'Selected',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.accentPink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (onPreview != null)
                IconButton(
                  tooltip: 'Preview sound',
                  onPressed: onPreview,
                  icon: AppSvgIcon(
                    assetPath: AppIcons.getIconPath('speaker'),
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FAQ accordion row inside a premium settings group.
class PremiumFaqTile extends StatelessWidget {
  const PremiumFaqTile({
    super.key,
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.cardBackgroundDark
            : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(
          color: AppColors.accentViolet.withValues(alpha: 0.1),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacingMD),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.spacingMD,
            0,
            AppSpacing.spacingMD,
            AppSpacing.spacingMD,
          ),
          title: Text(
            question,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          iconColor: AppColors.accentViolet,
          collapsedIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          children: [
            Text(
              answer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
