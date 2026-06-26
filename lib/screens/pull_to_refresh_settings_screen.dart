// Screen: PullToRefreshSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Pull to refresh settings screen - Manage pull to refresh preferences
class PullToRefreshSettingsScreen extends ConsumerStatefulWidget {
  const PullToRefreshSettingsScreen({super.key});

  @override
  ConsumerState<PullToRefreshSettingsScreen> createState() =>
      _PullToRefreshSettingsScreenState();
}

class _PullToRefreshSettingsScreenState
    extends ConsumerState<PullToRefreshSettingsScreen> {
  bool _pullToRefreshEnabled = true;
  String _refreshIndicatorStyle = 'material';
  double _refreshThreshold = 100.0;

  bool _showRefreshIndicator = true;
  String _indicatorColor = 'accent';

  bool _enableOnScroll = true;
  bool _enableOnSwipe = true;
  String _refreshTrigger = 'release';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from API or local storage
  }

  Future<void> _saveSettings() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pull to refresh settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  void _setStyle(String value) {
    setState(() => _refreshIndicatorStyle = value);
    _saveSettings();
  }

  void _setIndicatorColor(String value) {
    setState(() => _indicatorColor = value);
    _saveSettings();
  }

  void _setTrigger(String value) {
    setState(() => _refreshTrigger = value);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final surfaceColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor =
        AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1);

    return AppSettingsDetailScaffold(
      title: 'Pull to refresh',
      subtitle: 'Indicator style, threshold, and behavior',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'General',
            children: [
              PremiumToggleRow(
                title: 'Enable pull to refresh',
                subtitle: 'Allow lists to refresh by pulling down',
                value: _pullToRefreshEnabled,
                iconPath: AppIcons.refreshCircle,
                onChanged: (value) {
                  setState(() => _pullToRefreshEnabled = value);
                  _saveSettings();
                },
              ),
              if (_pullToRefreshEnabled) ...[
                _SettingOption(
                  label: 'Material Design',
                  isSelected: _refreshIndicatorStyle == 'material',
                  onSelect: () => _setStyle('material'),
                ),
                _SettingOption(
                  label: 'Cupertino (iOS)',
                  isSelected: _refreshIndicatorStyle == 'cupertino',
                  onSelect: () => _setStyle('cupertino'),
                ),
                _SettingOption(
                  label: 'Custom',
                  isSelected: _refreshIndicatorStyle == 'custom',
                  onSelect: () => _setStyle('custom'),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
                  padding: const EdgeInsets.all(AppSpacing.spacingMD),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusLG),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Refresh threshold',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_refreshThreshold.toInt()}px',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentViolet,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _refreshThreshold,
                        min: 50.0,
                        max: 200.0,
                        divisions: 15,
                        label: '${_refreshThreshold.toInt()}px',
                        activeColor: AppColors.accentViolet,
                        onChanged: (value) {
                          setState(() => _refreshThreshold = value);
                          _saveSettings();
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('50px', style: theme.textTheme.bodySmall),
                          Text('200px', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (_pullToRefreshEnabled) ...[
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Visual',
              children: [
                PremiumToggleRow(
                  title: 'Show refresh indicator',
                  subtitle: 'Display the refresh spinner while loading',
                  value: _showRefreshIndicator,
                  iconPath: AppIcons.eye,
                  onChanged: (value) {
                    setState(() => _showRefreshIndicator = value);
                    _saveSettings();
                  },
                ),
                _SettingOption(
                  label: 'Accent color',
                  isSelected: _indicatorColor == 'accent',
                  onSelect: () => _setIndicatorColor('accent'),
                ),
                _SettingOption(
                  label: 'Primary color',
                  isSelected: _indicatorColor == 'primary',
                  onSelect: () => _setIndicatorColor('primary'),
                ),
                _SettingOption(
                  label: 'Custom color',
                  isSelected: _indicatorColor == 'custom',
                  onSelect: () => _setIndicatorColor('custom'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Behavior',
              children: [
                PremiumToggleRow(
                  title: 'Enable on scroll',
                  subtitle: 'Allow pull to refresh when scrolling',
                  value: _enableOnScroll,
                  iconPath: AppIcons.arrowDown,
                  onChanged: (value) {
                    setState(() => _enableOnScroll = value);
                    _saveSettings();
                  },
                ),
                PremiumToggleRow(
                  title: 'Enable on swipe',
                  subtitle: 'Allow pull to refresh when swiping',
                  value: _enableOnSwipe,
                  iconPath: AppIcons.arrowDown2,
                  onChanged: (value) {
                    setState(() => _enableOnSwipe = value);
                    _saveSettings();
                  },
                ),
                _SettingOption(
                  label: 'On release',
                  isSelected: _refreshTrigger == 'release',
                  onSelect: () => _setTrigger('release'),
                ),
                _SettingOption(
                  label: 'On drag',
                  isSelected: _refreshTrigger == 'drag',
                  onSelect: () => _setTrigger('drag'),
                ),
              ],
            ),
          ],
          if (!_pullToRefreshEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSettingsLayout.horizontalPadding,
                AppSpacing.spacingMD,
                AppSettingsLayout.horizontalPadding,
                0,
              ),
              child: Text(
                'Enable pull to refresh above to customize indicator and behavior.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  const _SettingOption({
    required this.label,
    required this.isSelected,
    required this.onSelect,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PremiumTapScale(
      onTap: onSelect,
      semanticLabel: label,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacingMD,
          vertical: AppSpacing.spacingSM + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentViolet.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.cardBackgroundLight),
          borderRadius: BorderRadius.circular(AppRadius.radiusLG),
          border: Border.all(
            color: isSelected
                ? AppColors.accentViolet
                : AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              AppSvgIcon(
                assetPath: AppIcons.tickCircle,
                size: 20,
                color: AppColors.accentViolet,
              ),
          ],
        ),
      ),
    );
  }
}
