import 'package:flutter/material.dart';

import '../theme/border_radius_constants.dart';
import '../theme/spacing_constants.dart';
import '../utils/app_icons.dart';
import 'app_page_header.dart';

/// Muted section label above a grouped settings/menu card (REF profile layout).
class AppGroupedListSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppGroupedListSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppPageHeader.horizontalPadding,
            AppSpacing.spacingXL,
            AppPageHeader.horizontalPadding,
            0,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.spacingXS,
              top: AppSpacing.spacingXS,
              bottom: AppSpacing.spacingMD,
            ),
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Material(
            color: theme.colorScheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single row inside [AppGroupedListSection].
class AppGroupedListTile extends StatelessWidget {
  final String iconPath;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final Widget? trailing;

  const AppGroupedListTile({
    super.key,
    required this.iconPath,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingMD,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.radiusXS),
                      ),
                      child: Center(
                        child: AppSvgIcon(
                          assetPath: iconPath,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing ??
                        AppSvgIcon(
                          assetPath: AppIcons.chevronRight,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          _groupedDivider(theme, indent: AppSpacing.spacingMD + 32 + 14),
      ],
    );
  }
}

/// Switch row inside [AppGroupedListSection] (settings detail pages).
class AppGroupedSwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  const AppGroupedSwitchTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingMD,
          ),
          child: Row(
            children: [
              Expanded(child: _GroupedRowLabels(label: label, subtitle: subtitle)),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider) _groupedDivider(theme),
      ],
    );
  }
}

/// Single-choice row inside [AppGroupedListSection].
class AppGroupedOptionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDivider;

  const AppGroupedOptionTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.isSelected,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingMD,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _GroupedRowLabels(label: label, subtitle: subtitle),
                    ),
                    if (isSelected)
                      AppSvgIcon(
                        assetPath: AppIcons.tickCircle,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider) _groupedDivider(theme),
      ],
    );
  }
}

/// Sound/ringtone row with preview action inside [AppGroupedListSection].
class AppGroupedSoundOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onPreview;
  final bool showDivider;

  const AppGroupedSoundOptionTile({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelect,
    this.onPreview,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSelect,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingMD,
                  vertical: AppSpacing.spacingSM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _GroupedRowLabels(
                        label: label,
                        subtitle: isSelected ? 'Selected' : null,
                      ),
                    ),
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.spacingXS),
                        child: AppSvgIcon(
                          assetPath: AppIcons.tickCircle,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Preview',
                      onPressed: onPreview,
                      icon: AppSvgIcon(
                        assetPath: AppIcons.getIconPath('volume-high'),
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider) _groupedDivider(theme),
      ],
    );
  }
}

/// Read-only value row inside [AppGroupedListSection].
class AppGroupedInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final bool showDivider;

  const AppGroupedInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.badge,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacingMD,
            vertical: AppSpacing.spacingMD,
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Text(
                  badge!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) _groupedDivider(theme),
      ],
    );
  }
}

class _GroupedRowLabels extends StatelessWidget {
  final String label;
  final String? subtitle;

  const _GroupedRowLabels({required this.label, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

Divider _groupedDivider(ThemeData theme, {double indent = AppSpacing.spacingMD}) {
  return Divider(
    height: 0.5,
    thickness: 0.5,
    indent: indent,
    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
  );
}
