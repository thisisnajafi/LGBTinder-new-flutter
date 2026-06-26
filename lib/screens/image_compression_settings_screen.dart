// Screen: ImageCompressionSettingsScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/spacing_constants.dart';
import '../core/theme/border_radius_constants.dart';
import '../core/utils/app_icons.dart';
import '../core/widgets/app_settings_detail.dart';
import '../core/widgets/premium/premium_design_system.dart';

/// Image compression settings screen - Manage image quality and compression
class ImageCompressionSettingsScreen extends ConsumerStatefulWidget {
  const ImageCompressionSettingsScreen({super.key});

  @override
  ConsumerState<ImageCompressionSettingsScreen> createState() =>
      _ImageCompressionSettingsScreenState();
}

class _ImageCompressionSettingsScreenState
    extends ConsumerState<ImageCompressionSettingsScreen> {
  bool _autoCompress = true;
  String _imageQuality = 'high';
  int _qualityPercentage = 85;
  int _maxImageSize = 2048;
  int _maxFileSize = 5;

  String _preferredFormat = 'auto';
  bool _useWebP = true;

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
          const SnackBar(content: Text('Image compression settings saved')),
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

  void _setQuality(String value) {
    setState(() {
      _imageQuality = value;
      _qualityPercentage = switch (value) {
        'low' => 60,
        'medium' => 75,
        'high' => 85,
        'original' => 100,
        _ => 85,
      };
    });
    _saveSettings();
  }

  void _setFormat(String value) {
    setState(() => _preferredFormat = value);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return AppSettingsDetailScaffold(
      title: 'Image compression',
      subtitle: 'Quality, size limits, and upload format',
      body: AppSettingsDetailList(
        children: [
          PremiumSettingsGroup(
            title: 'Compression',
            children: [
              PremiumToggleRow(
                title: 'Auto compress images',
                subtitle: 'Compress images automatically when uploading',
                value: _autoCompress,
                iconPath: AppIcons.image,
                onChanged: (value) {
                  setState(() => _autoCompress = value);
                  _saveSettings();
                },
              ),
              if (_autoCompress) ...[
                _SettingOption(
                  label: 'Low (smaller files)',
                  isSelected: _imageQuality == 'low',
                  onSelect: () => _setQuality('low'),
                ),
                _SettingOption(
                  label: 'Medium (balanced)',
                  isSelected: _imageQuality == 'medium',
                  onSelect: () => _setQuality('medium'),
                ),
                _SettingOption(
                  label: 'High (better quality)',
                  isSelected: _imageQuality == 'high',
                  onSelect: () => _setQuality('high'),
                ),
                _SettingOption(
                  label: 'Original (no compression)',
                  isSelected: _imageQuality == 'original',
                  onSelect: () => _setQuality('original'),
                ),
                if (_imageQuality != 'original')
                  _SliderCard(
                    title: 'Quality percentage',
                    valueLabel: '$_qualityPercentage%',
                    minLabel: '50%',
                    maxLabel: '100%',
                    slider: Slider(
                      value: _qualityPercentage.toDouble(),
                      min: 50,
                      max: 100,
                      divisions: 10,
                      label: '$_qualityPercentage%',
                      activeColor: AppColors.accentViolet,
                      onChanged: (value) {
                        setState(() {
                          _qualityPercentage = value.toInt();
                          _imageQuality = value < 65
                              ? 'low'
                              : value < 80
                                  ? 'medium'
                                  : 'high';
                        });
                        _saveSettings();
                      },
                    ),
                  ),
                _SliderCard(
                  title: 'Max image size',
                  valueLabel: '${_maxImageSize}px',
                  minLabel: '1024px',
                  maxLabel: '4096px',
                  slider: Slider(
                    value: _maxImageSize.toDouble(),
                    min: 1024,
                    max: 4096,
                    divisions: 6,
                    label: '${_maxImageSize}px',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _maxImageSize = value.toInt());
                      _saveSettings();
                    },
                  ),
                ),
                _SliderCard(
                  title: 'Max file size',
                  valueLabel: '$_maxFileSize MB',
                  minLabel: '1 MB',
                  maxLabel: '10 MB',
                  slider: Slider(
                    value: _maxFileSize.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_maxFileSize MB',
                    activeColor: AppColors.accentViolet,
                    onChanged: (value) {
                      setState(() => _maxFileSize = value.toInt());
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ],
          ),
          if (_autoCompress) const SizedBox(height: AppSpacing.spacingXL),
          PremiumSettingsGroup(
            title: 'Format',
            children: [
              _SettingOption(
                label: 'Auto (best format)',
                isSelected: _preferredFormat == 'auto',
                onSelect: () => _setFormat('auto'),
              ),
              _SettingOption(
                label: 'JPEG',
                isSelected: _preferredFormat == 'jpeg',
                onSelect: () => _setFormat('jpeg'),
              ),
              _SettingOption(
                label: 'WebP',
                isSelected: _preferredFormat == 'webp',
                onSelect: () => _setFormat('webp'),
              ),
              _SettingOption(
                label: 'PNG',
                isSelected: _preferredFormat == 'png',
                onSelect: () => _setFormat('png'),
              ),
              PremiumToggleRow(
                title: 'Prefer WebP',
                subtitle: 'Use WebP when available for better compression',
                value: _useWebP,
                iconPath: AppIcons.documentText,
                onChanged: (value) {
                  setState(() => _useWebP = value);
                  _saveSettings();
                },
              ),
            ],
          ),
          if (!_autoCompress)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSettingsLayout.horizontalPadding,
                AppSpacing.spacingMD,
                AppSettingsLayout.horizontalPadding,
                0,
              ),
              child: Text(
                'Enable auto compress above to adjust quality and size limits.',
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
