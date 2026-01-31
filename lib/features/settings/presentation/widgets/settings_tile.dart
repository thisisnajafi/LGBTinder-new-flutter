import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';

/// Settings tile widget
/// Displays individual setting items with icons and actions
class SettingsTile extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final String? iconPath;
  final IconData? iconData;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColor;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const SettingsTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.iconPath,
    this.iconData,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconColor,
    this.showDivider = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final w = MediaQuery.sizeOf(context).width;
    final iconSize = (w * 0.1).clamp(36.0, 48.0);
    final iconInnerSize = (iconSize * 0.5).clamp(18.0, 24.0);

    return Column(
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                if (iconPath != null || iconData != null) ...[
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.primaryLight).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: iconPath != null
                          ? AppSvgIcon(
                              assetPath: iconPath!,
                              size: iconInnerSize,
                              color: iconColor ?? AppColors.primaryLight,
                            )
                          : Icon(
                              iconData,
                              size: iconInnerSize,
                              color: iconColor ?? AppColors.primaryLight,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing widget
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ] else if (onTap != null) ...[
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Divider
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            indent: iconPath != null || iconData != null ? (iconSize + 24) : 16,
          ),
      ],
    );
  }
}

/// Navigation settings tile
class NavigationSettingsTile extends SettingsTile {
  const NavigationSettingsTile({
    Key? key,
    required String title,
    String? subtitle,
    String? iconPath,
    IconData? iconData,
    Color? iconColor,
    required VoidCallback onTap,
    bool enabled = true,
    bool showDivider = true,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          iconPath: iconPath,
          iconData: iconData,
          iconColor: iconColor,
          onTap: onTap,
          enabled: enabled,
          showDivider: showDivider,
        );
}

/// Action settings tile (for destructive actions)
class ActionSettingsTile extends SettingsTile {
  const ActionSettingsTile({
    Key? key,
    required String title,
    String? subtitle,
    String? iconPath,
    IconData? iconData,
    required VoidCallback onTap,
    bool enabled = true,
    bool showDivider = true,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          iconPath: iconPath,
          iconData: iconData,
          iconColor: AppColors.feedbackError,
          onTap: onTap,
          enabled: enabled,
          showDivider: showDivider,
        );
}

/// Info settings tile (non-interactive)
class InfoSettingsTile extends SettingsTile {
  const InfoSettingsTile({
    Key? key,
    required String title,
    String? subtitle,
    String? iconPath,
    IconData? iconData,
    Color? iconColor,
    bool showDivider = true,
  }) : super(
          key: key,
          title: title,
          subtitle: subtitle,
          iconPath: iconPath,
          iconData: iconData,
          iconColor: iconColor,
          enabled: false,
          showDivider: showDivider,
        );
}
