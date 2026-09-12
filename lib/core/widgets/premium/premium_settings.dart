import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/border_radius_constants.dart';
import '../../theme/spacing_constants.dart';
import '../../utils/app_icons.dart';
import 'premium_shell.dart';
import '../../responsive/responsive.dart';

/// Inner chip card used on the profile page and edit-profile controls.
class PremiumInsetCard extends StatelessWidget {
  const PremiumInsetCard({
    super.key,
    required this.child,
    this.accent = AppColors.accentViolet,
    this.margin,
    this.padding = const EdgeInsets.all(AppSpacing.spacingMD),
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.radiusLG),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

/// Branded switch matching profile-edit lifestyle controls.
class PremiumSwitch extends StatelessWidget {
  const PremiumSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleTrack = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.12);

    return Semantics(
      toggled: value,
      child: IgnorePointer(
        ignoring: onChanged == null,
        child: Switch(
          value: value,
          onChanged: onChanged ?? (_) {},
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(
            AppColors.accentPink.withValues(alpha: 0.16),
          ),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.accentPink;
            }
            return idleTrack;
          }),
        ),
      ),
    );
  }
}

/// Boolean trailing control — same pink switch as profile edit.
class PremiumCheckbox extends StatelessWidget {
  const PremiumCheckbox({
    super.key,
    required this.selected,
    this.size = 22,
    this.onChanged,
  });

  final bool selected;
  final double size;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumSwitch(value: selected, onChanged: onChanged);
  }
}

/// Single row inside a premium settings group.
class PremiumSettingsTile extends StatelessWidget {
  const PremiumSettingsTile({
    super.key,
    required this.iconPath,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.selected,
    this.accent = AppColors.accentViolet,
    this.destructive = false,
  });

  final String iconPath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  /// When set, the row is a selectable choice and shows a checkbox instead of a chevron.
  final bool? selected;
  final Color accent;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = destructive ? AppColors.feedbackError : accent;
    final titleColor =
        destructive ? AppColors.feedbackError : theme.colorScheme.onSurface;
    final isChoice = selected != null;

    final row = Row(
      children: [
        Container(
          width: isChoice ? 36 : 40,
          height: isChoice ? 36 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withValues(alpha: isChoice ? 0.15 : 0.12),
          ),
          child: Center(
            child: AppSvgIcon(
              assetPath: iconPath,
              size: isChoice ? 18 : 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
                maxLines: 2,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                AppText(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
        trailing ??
            (isChoice
                ? PremiumSwitch(
                    value: selected!,
                    onChanged: (value) {
                      if (value != selected) onTap();
                    },
                  )
                : AppSvgIcon(
                    assetPath: AppIcons.getIconPath('arrow-right-3'),
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  )),
      ],
    );

    return PremiumTapScale(
      onTap: onTap,
      semanticLabel: title,
      child: SizedBox(
        width: double.infinity,
        child: isChoice
            ? PremiumInsetCard(
                accent: selected! ? AppColors.accentPink : accent,
                margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                child: row,
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacingSM),
                child: row,
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
    final rowOpacity = enabled ? 1.0 : 0.55;

    return Opacity(
      opacity: rowOpacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged(!value) : null,
        child: PremiumInsetCard(
          accent: value ? AppColors.accentPink : accent,
          margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
          child: Row(
            children: [
              if (iconPath != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: iconPath!,
                      size: 18,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                    AppText(
                      subtitle ?? (value ? 'Yes' : 'No'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              PremiumSwitch(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
            ],
          ),
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

    return PremiumInsetCard(
      accent: badgeColor ?? AppColors.accentViolet,
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
                AppText(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          if (badge != null)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.accentPink)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: AppText(
                  badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeColor ?? AppColors.accentPink,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.end,
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
    final accent = isSelected ? AppColors.accentPink : AppColors.accentViolet;

    return PremiumTapScale(
      onTap: onSelect ?? () {},
      semanticLabel: label,
      child: Opacity(
        opacity: onSelect == null ? 0.55 : 1,
        child: PremiumInsetCard(
          accent: accent,
          margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingSM,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
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
              PremiumSwitch(
                value: isSelected,
                onChanged: onSelect == null
                    ? null
                    : (value) {
                        if (value != isSelected) onSelect!();
                      },
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
          title: AppText(
            question,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 3,
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
