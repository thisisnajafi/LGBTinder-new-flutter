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
              bottom: AppSpacing.spacingSM,
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
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: AppSpacing.spacingMD + 32 + 14,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
      ],
    );
  }
}
