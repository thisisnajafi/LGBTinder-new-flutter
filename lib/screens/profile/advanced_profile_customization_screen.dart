// Screen: AdvancedProfileCustomizationScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../features/profile/utils/profile_customization_draft.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Advanced profile customization — section isolate + draft (PERF-SCR-CUSTOM-001).
class AdvancedProfileCustomizationScreen extends ConsumerStatefulWidget {
  const AdvancedProfileCustomizationScreen({super.key});

  @override
  ConsumerState<AdvancedProfileCustomizationScreen> createState() =>
      _AdvancedProfileCustomizationScreenState();
}

class _AdvancedProfileCustomizationScreenState
    extends ConsumerState<AdvancedProfileCustomizationScreen> {
  final ProfileCustomizationDraft _draft = ProfileCustomizationDraft();
  final ValueNotifier<double> _opacity = ValueNotifier(1);
  final ValueNotifier<bool> _saving = ValueNotifier(false);

  @override
  void dispose() {
    _draft.dispose();
    _opacity.dispose();
    _saving.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    _saving.value = true;
    _draft.setOpacity(_opacity.value);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      AlertDialogCustom.show(
        context,
        title: 'Settings Saved',
        message: 'Your customization settings have been saved!',
        iconPath: AppIcons.checkCircle,
        iconColor: AppColors.onlineGreen,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) _saving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return AppPageScaffold(
      title: 'Advanced Customization',
      showBackButton: true,
      backgroundColor: backgroundColor,
      action: ValueListenableBuilder<bool>(
        valueListenable: _saving,
        builder: (context, saving, _) {
          if (saving) {
            return Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentPurple,
                  ),
                ),
              ),
            );
          }
          return TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: AppTypography.button.copyWith(
                color: AppColors.accentPurple,
              ),
            ),
          );
        },
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          _LayoutSection(
            draft: _draft,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          _ColorSchemeSection(
            draft: _draft,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          _DisplaySection(
            draft: _draft,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          _BioStyleSection(
            draft: _draft,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          _AdvancedSection(
            draft: _draft,
            opacity: _opacity,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
          ),
          SizedBox(height: AppSpacing.spacingXXL),
          ValueListenableBuilder<bool>(
            valueListenable: _saving,
            builder: (context, saving, _) {
              return GradientButton(
                text: 'Save Customization',
                onPressed: saving ? null : _saveSettings,
                isLoading: saving,
                isFullWidth: true,
                iconPath: AppIcons.save,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LayoutSection extends StatelessWidget {
  const _LayoutSection({
    required this.draft,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final ProfileCustomizationDraft draft;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Layout Options',
              iconPath: AppIcons.menu,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _SelectableRow(
              label: 'Default',
              iconPath: AppIcons.menu1,
              selected: draft.layout == 'default',
              onTap: () => draft.setLayout('default'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SelectableRow(
              label: 'Compact',
              iconPath: AppIcons.moreSquare,
              selected: draft.layout == 'compact',
              onTap: () => draft.setLayout('compact'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SelectableRow(
              label: 'Expanded',
              iconPath: AppIcons.document,
              selected: draft.layout == 'expanded',
              onTap: () => draft.setLayout('expanded'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
        );
      },
    );
  }
}

class _ColorSchemeSection extends StatelessWidget {
  const _ColorSchemeSection({
    required this.draft,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final ProfileCustomizationDraft draft;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Color Scheme',
              iconPath: AppIcons.star,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _ColorRow(
              label: 'Default',
              colors: const [AppColors.accentPurple],
              selected: draft.colorScheme == 'default',
              onTap: () => draft.setColorScheme('default'),
              textColor: textColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _ColorRow(
              label: 'Rainbow',
              colors: AppColors.lgbtGradient,
              selected: draft.colorScheme == 'rainbow',
              onTap: () => draft.setColorScheme('rainbow'),
              textColor: textColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _ColorRow(
              label: 'Monochrome',
              colors: const [AppColors.textSecondaryLight],
              selected: draft.colorScheme == 'monochrome',
              onTap: () => draft.setColorScheme('monochrome'),
              textColor: textColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
        );
      },
    );
  }
}

class _DisplaySection extends StatelessWidget {
  const _DisplaySection({
    required this.draft,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final ProfileCustomizationDraft draft;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Display Options',
              iconPath: AppIcons.setting,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _SwitchRow(
              title: 'Show Badges',
              description: 'Display verification and premium badges',
              value: draft.showBadges,
              onChanged: draft.setShowBadges,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SwitchRow(
              title: 'Show Stats',
              description: 'Display profile statistics',
              value: draft.showStats,
              onChanged: draft.setShowStats,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SwitchRow(
              title: 'Show Interests',
              description: 'Display interests section',
              value: draft.showInterests,
              onChanged: draft.setShowInterests,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SwitchRow(
              title: 'Show Education',
              description: 'Display education section',
              value: draft.showEducation,
              onChanged: draft.setShowEducation,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SwitchRow(
              title: 'Show Work',
              description: 'Display work section',
              value: draft.showWork,
              onChanged: draft.setShowWork,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
        );
      },
    );
  }
}

class _BioStyleSection extends StatelessWidget {
  const _BioStyleSection({
    required this.draft,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final ProfileCustomizationDraft draft;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Bio Style',
              iconPath: AppIcons.documentText,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            _SelectableRow(
              label: 'Standard',
              selected: draft.bioStyle == 'standard',
              onTap: () => draft.setBioStyle('standard'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SelectableRow(
              label: 'Minimal',
              selected: draft.bioStyle == 'minimal',
              onTap: () => draft.setBioStyle('minimal'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
            SizedBox(height: AppSpacing.spacingSM),
            _SelectableRow(
              label: 'Detailed',
              selected: draft.bioStyle == 'detailed',
              onTap: () => draft.setBioStyle('detailed'),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            ),
          ],
        );
      },
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({
    required this.draft,
    required this.opacity,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final ProfileCustomizationDraft draft;
  final ValueNotifier<double> opacity;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Advanced Options',
          iconPath: AppIcons.settings,
        ),
        SizedBox(height: AppSpacing.spacingMD),
        ListenableBuilder(
          listenable: draft,
          builder: (context, _) {
            return _SwitchRow(
              title: 'Enable Animations',
              description: 'Show profile animations',
              value: draft.enableAnimations,
              onChanged: draft.setEnableAnimations,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            );
          },
        ),
        SizedBox(height: AppSpacing.spacingMD),
        ValueListenableBuilder<double>(
          valueListenable: opacity,
          builder: (context, value, _) {
            return Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          'Profile Opacity',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingMD),
                  Slider(
                    value: value,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    activeColor: AppColors.accentPurple,
                    onChanged: (next) => opacity.value = next,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
    this.iconPath,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: selected ? AppColors.accentPurple : borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              if (iconPath != null) ...[
                AppSvgIcon(
                  assetPath: iconPath!,
                  size: 22,
                  color: selected
                      ? AppColors.accentPurple
                      : secondaryTextColor,
                ),
                SizedBox(width: AppSpacing.spacingMD),
              ],
              Expanded(
                child: AppText(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                ),
              ),
              if (selected)
                AppSvgIcon(
                  assetPath: AppIcons.checkCircle,
                  size: 22,
                  color: AppColors.accentPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.colors,
    required this.selected,
    required this.onTap,
    required this.textColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final String label;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;
  final Color textColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: selected ? AppColors.accentPurple : borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.spacingMD),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient:
                      colors.length > 1 ? LinearGradient(colors: colors) : null,
                  color: colors.length == 1 ? colors[0] : null,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: AppText(
                  label,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                ),
              ),
              if (selected)
                AppSvgIcon(
                  assetPath: AppIcons.checkCircle,
                  size: 22,
                  color: AppColors.accentPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.textColor,
    required this.secondaryTextColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textColor;
  final Color secondaryTextColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: AppTypography.body.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: AppSpacing.spacingXS),
                AppText(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: secondaryTextColor,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentPurple,
          ),
        ],
      ),
    );
  }
}
