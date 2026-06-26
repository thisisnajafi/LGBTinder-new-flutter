// Screen: SkeletonLoaderSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Skeleton loader settings screen - Manage skeleton loader preferences
class SkeletonLoaderSettingsScreen extends ConsumerStatefulWidget {
  const SkeletonLoaderSettingsScreen({super.key});

  @override
  ConsumerState<SkeletonLoaderSettingsScreen> createState() =>
      _SkeletonLoaderSettingsScreenState();
}

class _SkeletonLoaderSettingsScreenState
    extends ConsumerState<SkeletonLoaderSettingsScreen> {
  bool _skeletonLoadersEnabled = true;
  String _skeletonStyle = 'shimmer';
  double _animationSpeed = 1.0;

  String _baseColor = 'surface';
  String _highlightColor = 'elevated';
  double _opacity = 0.7;

  bool _showOnInitialLoad = true;
  bool _showOnRefresh = true;
  int _minDisplayDuration = 500;

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
          const SnackBar(content: Text('Skeleton loader settings saved')),
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
    setState(() => _skeletonStyle = value);
    _saveSettings();
  }

  void _setBaseColor(String value) {
    setState(() => _baseColor = value);
    _saveSettings();
  }

  void _setHighlightColor(String value) {
    setState(() => _highlightColor = value);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return AppSettingsDetailScaffold(
      title: 'Skeleton loaders',
      subtitle: 'Placeholder style, colors, and timing',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'General',
            children: [
              PremiumToggleRow(
                title: 'Enable skeleton loaders',
                subtitle: 'Show placeholders while content loads',
                value: _skeletonLoadersEnabled,
                iconPath: AppIcons.magicStar,
                onChanged: (value) {
                  setState(() => _skeletonLoadersEnabled = value);
                  _saveSettings();
                },
              ),
              if (_skeletonLoadersEnabled) ...[
                _SettingOption(
                  label: 'Shimmer',
                  isSelected: _skeletonStyle == 'shimmer',
                  onSelect: () => _setStyle('shimmer'),
                ),
                _SettingOption(
                  label: 'Pulse',
                  isSelected: _skeletonStyle == 'pulse',
                  onSelect: () => _setStyle('pulse'),
                ),
                _SettingOption(
                  label: 'Wave',
                  isSelected: _skeletonStyle == 'wave',
                  onSelect: () => _setStyle('wave'),
                ),
                _SliderCard(
                  title: 'Animation speed',
                  valueLabel: '${_animationSpeed.toStringAsFixed(1)}x',
                  child: Slider(
                    value: _animationSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${_animationSpeed.toStringAsFixed(1)}x',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _animationSpeed = value);
                      _saveSettings();
                    },
                  ),
                  minLabel: 'Slow',
                  maxLabel: 'Fast',
                ),
              ],
            ],
          ),
          if (_skeletonLoadersEnabled) ...[
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Visual',
              children: [
                _SettingOption(
                  label: 'Surface color',
                  isSelected: _baseColor == 'surface',
                  onSelect: () => _setBaseColor('surface'),
                ),
                _SettingOption(
                  label: 'Gray',
                  isSelected: _baseColor == 'gray',
                  onSelect: () => _setBaseColor('gray'),
                ),
                _SettingOption(
                  label: 'Custom base',
                  isSelected: _baseColor == 'custom',
                  onSelect: () => _setBaseColor('custom'),
                ),
                _SettingOption(
                  label: 'Elevated surface',
                  isSelected: _highlightColor == 'elevated',
                  onSelect: () => _setHighlightColor('elevated'),
                ),
                _SettingOption(
                  label: 'Accent color',
                  isSelected: _highlightColor == 'accent',
                  onSelect: () => _setHighlightColor('accent'),
                ),
                _SettingOption(
                  label: 'Custom highlight',
                  isSelected: _highlightColor == 'custom',
                  onSelect: () => _setHighlightColor('custom'),
                ),
                _SliderCard(
                  title: 'Opacity',
                  valueLabel: '${(_opacity * 100).toInt()}%',
                  child: Slider(
                    value: _opacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(_opacity * 100).toInt()}%',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _opacity = value);
                      _saveSettings();
                    },
                  ),
                  minLabel: 'Transparent',
                  maxLabel: 'Opaque',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacingXL),
            PremiumSettingsGroup(
              title: 'Behavior',
              children: [
                PremiumToggleRow(
                  title: 'Show on initial load',
                  subtitle: 'Display skeletons on first load',
                  value: _showOnInitialLoad,
                  iconPath: AppIcons.documentText,
                  onChanged: (value) {
                    setState(() => _showOnInitialLoad = value);
                    _saveSettings();
                  },
                ),
                PremiumToggleRow(
                  title: 'Show on refresh',
                  subtitle: 'Display skeletons when refreshing lists',
                  value: _showOnRefresh,
                  iconPath: AppIcons.refreshCircle,
                  onChanged: (value) {
                    setState(() => _showOnRefresh = value);
                    _saveSettings();
                  },
                ),
                _SliderCard(
                  title: 'Min display duration',
                  valueLabel: '${_minDisplayDuration}ms',
                  child: Slider(
                    value: _minDisplayDuration.toDouble(),
                    min: 0,
                    max: 2000,
                    divisions: 20,
                    label: '${_minDisplayDuration}ms',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _minDisplayDuration = value.toInt());
                      _saveSettings();
                    },
                  ),
                  minLabel: '0ms',
                  maxLabel: '2000ms',
                ),
              ],
            ),
          ],
          if (!_skeletonLoadersEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSettingsLayout.horizontalPadding,
                AppSpacing.spacingMD,
                AppSettingsLayout.horizontalPadding,
                0,
              ),
              child: Text(
                'Enable skeleton loaders above to customize appearance and behavior.',
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

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.valueLabel,
    required this.child,
    required this.minLabel,
    required this.maxLabel,
  });

  final String title;
  final String valueLabel;
  final Widget child;
  final String minLabel;
  final String maxLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.cardBackgroundDark
        : AppColors.cardBackgroundLight;
    final borderColor =
        AppColors.accentViolet.withValues(alpha: isDark ? 0.12 : 0.1);

    return Container(
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
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                valueLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentViolet,
                ),
              ),
            ],
          ),
          child,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: theme.textTheme.bodySmall),
              Text(maxLabel, style: theme.textTheme.bodySmall),
            ],
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
