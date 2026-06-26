// Screen: MediaPickerSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Media picker settings screen - Manage media picker preferences
class MediaPickerSettingsScreen extends ConsumerStatefulWidget {
  const MediaPickerSettingsScreen({super.key});

  @override
  ConsumerState<MediaPickerSettingsScreen> createState() =>
      _MediaPickerSettingsScreenState();
}

class _MediaPickerSettingsScreenState
    extends ConsumerState<MediaPickerSettingsScreen> {
  bool _allowCamera = true;
  bool _allowGallery = true;
  String _defaultSource = 'gallery';

  bool _allowPhotos = true;
  bool _allowVideos = true;
  bool _allowMultiple = true;
  int _maxSelections = 10;

  bool _showPreview = true;
  bool _enableCropping = true;
  bool _enableFilters = false;

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
          const SnackBar(content: Text('Media picker settings saved')),
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

  void _setDefaultSource(String value) {
    setState(() => _defaultSource = value);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsDetailScaffold(
      title: 'Media picker',
      subtitle: 'Sources, types, and preview options',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Source',
            children: [
              PremiumToggleRow(
                title: 'Allow camera',
                subtitle: 'Enable camera as a media source',
                value: _allowCamera,
                iconPath: AppIcons.camera,
                onChanged: (value) {
                  setState(() {
                    _allowCamera = value;
                    if (!value && _defaultSource == 'camera') {
                      _defaultSource = 'gallery';
                    }
                  });
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Allow gallery',
                subtitle: 'Enable gallery as a media source',
                value: _allowGallery,
                iconPath: AppIcons.gallery,
                onChanged: (value) {
                  setState(() {
                    _allowGallery = value;
                    if (!value && _defaultSource == 'gallery') {
                      _defaultSource = 'camera';
                    }
                  });
                  _saveSettings();
                },
              ),
              if (_allowCamera)
                _SettingOption(
                  label: 'Camera',
                  isSelected: _defaultSource == 'camera',
                  onSelect: () => _setDefaultSource('camera'),
                ),
              if (_allowGallery)
                _SettingOption(
                  label: 'Gallery',
                  isSelected: _defaultSource == 'gallery',
                  onSelect: () => _setDefaultSource('gallery'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Media types',
            children: [
              PremiumToggleRow(
                title: 'Allow photos',
                subtitle: 'Enable photo selection',
                value: _allowPhotos,
                iconPath: AppIcons.image,
                onChanged: (value) {
                  setState(() => _allowPhotos = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Allow videos',
                subtitle: 'Enable video selection',
                value: _allowVideos,
                iconPath: AppIcons.video,
                onChanged: (value) {
                  setState(() => _allowVideos = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Multiple selection',
                subtitle: 'Allow selecting multiple media items',
                value: _allowMultiple,
                iconPath: AppIcons.galleryAdd,
                onChanged: (value) {
                  setState(() => _allowMultiple = value);
                  _saveSettings();
                },
              ),
              if (_allowMultiple)
                _SliderCard(
                  title: 'Max selections',
                  valueLabel: '$_maxSelections',
                  minLabel: '1',
                  maxLabel: '20',
                  slider: Slider(
                    value: _maxSelections.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '$_maxSelections',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _maxSelections = value.toInt());
                      _saveSettings();
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Preview & editing',
            children: [
              PremiumToggleRow(
                title: 'Show preview',
                subtitle: 'Preview before confirming selection',
                value: _showPreview,
                iconPath: AppIcons.eye,
                onChanged: (value) {
                  setState(() => _showPreview = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Enable cropping',
                subtitle: 'Allow cropping images before upload',
                value: _enableCropping,
                iconPath: AppIcons.galleryEdit,
                onChanged: (value) {
                  setState(() => _enableCropping = value);
                  _saveSettings();
                },
              ),
              PremiumToggleRow(
                title: 'Enable filters',
                subtitle: 'Allow applying filters to images',
                value: _enableFilters,
                iconPath: AppIcons.filter,
                onChanged: (value) {
                  setState(() => _enableFilters = value);
                  _saveSettings();
                },
              ),
            ],
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
    required this.minLabel,
    required this.maxLabel,
    required this.slider,
  });

  final String title;
  final String valueLabel;
  final String minLabel;
  final String maxLabel;
  final Widget slider;

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
          slider,
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
