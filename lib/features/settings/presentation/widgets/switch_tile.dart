import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common/app_svg_icon.dart';
import '../../../../core/utils/app_icons.dart';
import 'settings_tile.dart';

/// Switch tile widget
/// Settings tile with a toggle switch
class SwitchTile extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final String? iconPath;
  final IconData? iconData;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final Color? activeColor;
  final Color? iconColor;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const SwitchTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.iconPath,
    this.iconData,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.activeColor,
    this.iconColor,
    this.showDivider = true,
    this.padding,
  }) : super(key: key);

  @override
  ConsumerState<SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends ConsumerState<SwitchTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(SwitchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: widget.enabled && widget.onChanged != null
              ? () => _handleToggle()
              : null,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                if (widget.iconPath != null || widget.iconData != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (widget.iconColor ?? AppColors.primaryLight).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: widget.iconPath != null
                          ? AppSvgIcon(
                              assetPath: widget.iconPath!,
                              size: 20,
                              color: widget.iconColor ?? AppColors.primaryLight,
                            )
                          : Icon(
                              widget.iconData,
                              size: 20,
                              color: widget.iconColor ?? AppColors.primaryLight,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: widget.enabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Switch
                Switch(
                  value: _value,
                  onChanged: widget.enabled ? _handleToggle : null,
                  activeColor: widget.activeColor ?? AppColors.primaryLight,
                  activeTrackColor: (widget.activeColor ?? AppColors.primaryLight).withOpacity(0.3),
                  inactiveThumbColor: isDark ? Colors.grey[400] : Colors.grey[300],
                  inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
              ],
            ),
          ),
        ),

        // Divider
        if (widget.showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            indent: widget.iconPath != null || widget.iconData != null ? 64 : 16,
          ),
      ],
    );
  }

  void _handleToggle() {
    if (widget.onChanged != null) {
      final newValue = !_value;
      setState(() => _value = newValue);
      widget.onChanged!(newValue);
    }
  }
}

/// Theme switch tile (for light/dark mode)
class ThemeSwitchTile extends ConsumerWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const ThemeSwitchTile({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SettingsTile(
      title: 'Theme',
      subtitle: _getThemeDisplayName(currentTheme),
      iconData: currentTheme == 'dark'
          ? Icons.dark_mode
          : currentTheme == 'light'
              ? Icons.light_mode
              : Icons.brightness_auto,
      iconColor: currentTheme == 'dark'
          ? Colors.orange
          : currentTheme == 'light'
              ? Colors.yellow
              : AppColors.primaryLight,
      trailing: DropdownButton<String>(
        value: currentTheme,
        onChanged: (value) {
          if (value != null) {
            onThemeChanged(value);
          }
        },
        items: [
          DropdownMenuItem(
            value: 'system',
            child: Text(
              'System',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          DropdownMenuItem(
            value: 'light',
            child: Text(
              'Light',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          DropdownMenuItem(
            value: 'dark',
            child: Text(
              'Dark',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
        underline: const SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'light':
        return 'Light mode';
      case 'dark':
        return 'Dark mode';
      case 'system':
      default:
        return 'System default';
    }
  }
}

/// Notification switch tile
class NotificationSwitchTile extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final Function(bool) onChanged;

  const NotificationSwitchTile({
    Key? key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchTile(
      title: title,
      subtitle: subtitle,
      iconPath: AppIcons.notification,
      value: value,
      onChanged: onChanged,
      iconColor: value ? AppColors.primaryLight : Colors.grey,
    );
  }
}
