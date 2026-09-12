// Screen: ProfileExportScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import '../../core/widgets/app_page_scaffold.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

class _ExportFormat {
  const _ExportFormat({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
  });

  final String id;
  final String name;
  final String description;
  final String iconPath;
}

const _exportFormats = [
  _ExportFormat(
    id: 'JSON',
    name: 'JSON',
    description: 'Machine-readable format',
    iconPath: AppIcons.documentText,
  ),
  _ExportFormat(
    id: 'PDF',
    name: 'PDF',
    description: 'Printable document',
    iconPath: AppIcons.document,
  ),
  _ExportFormat(
    id: 'CSV',
    name: 'CSV',
    description: 'Spreadsheet format',
    iconPath: AppIcons.document1,
  ),
];

Stream<double> profileExportProgressStream() async* {
  for (var step = 1; step <= 10; step++) {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    yield step / 10;
  }
}

/// Profile export screen - Export profile data
class ProfileExportScreen extends ConsumerStatefulWidget {
  const ProfileExportScreen({super.key});

  @override
  ConsumerState<ProfileExportScreen> createState() =>
      _ProfileExportScreenState();
}

class _ProfileExportScreenState extends ConsumerState<ProfileExportScreen> {
  final ValueNotifier<bool> _isExporting = ValueNotifier(false);
  final ValueNotifier<double> _exportProgress = ValueNotifier(0);
  String? _lastExportDate;
  final List<String> _selectedFormats = ['JSON'];

  @override
  void dispose() {
    _isExporting.dispose();
    _exportProgress.dispose();
    super.dispose();
  }

  Future<void> _exportProfile() async {
    if (_selectedFormats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one format')),
      );
      return;
    }

    _isExporting.value = true;
    _exportProgress.value = 0;
    try {
      await for (final progress in profileExportProgressStream()) {
        if (!mounted) return;
        _exportProgress.value = progress;
      }
      if (!mounted) return;
      setState(() {
        _lastExportDate = DateTime.now().toIso8601String();
      });
      AlertDialogCustom.show(
        context,
        title: 'Export Complete',
        message: 'Your profile data has been exported successfully!',
        iconPath: AppIcons.checkCircle,
        iconColor: AppColors.onlineGreen,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        _isExporting.value = false;
        _exportProgress.value = 0;
      }
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
      title: 'Export Profile',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          const SectionHeader(
            title: 'Export Your Data',
            iconPath: AppIcons.download,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Download a copy of your profile data in your preferred format',
            style: AppTypography.body.copyWith(color: secondaryTextColor),
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'Export Formats',
            iconPath: AppIcons.documentText,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ..._exportFormats.map((format) {
            final isSelected = _selectedFormats.contains(format.id);
            return _buildFormatOption(
              format: format,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFormats.remove(format.id);
                  } else {
                    _selectedFormats.add(format.id);
                  }
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            );
          }),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          const SectionHeader(
            title: 'Data Included',
            iconPath: AppIcons.infoCircle,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _buildDataItem('Profile Information', textColor),
                _buildDataItem('Photos', textColor),
                _buildDataItem('Interests & Preferences', textColor),
                _buildDataItem('Match History', textColor),
                _buildDataItem('Messages (if requested)', textColor),
              ],
            ),
          ),
          const DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),
          if (_lastExportDate != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: AppColors.onlineGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  AppSvgIcon(
                    assetPath: AppIcons.checkCircle,
                    size: 24,
                    color: AppColors.onlineGreen,
                  ),
                  SizedBox(width: AppSpacing.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Export',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacingXS),
                        Text(
                          _formatDate(_lastExportDate!),
                          style: AppTypography.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: AppSpacing.spacingLG),
          ValueListenableBuilder<bool>(
            valueListenable: _isExporting,
            builder: (context, exporting, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GradientButton(
                    text: exporting ? 'Exporting...' : 'Export Profile Data',
                    onPressed: exporting ? null : _exportProfile,
                    isLoading: exporting,
                    isFullWidth: true,
                    iconPath: AppIcons.download,
                  ),
                  if (exporting) ...[
                    SizedBox(height: AppSpacing.spacingMD),
                    ValueListenableBuilder<double>(
                      valueListenable: _exportProgress,
                      builder: (context, progress, _) {
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentPurple,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
          SizedBox(height: AppSpacing.spacingLG),
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.accentPurple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSvgIcon(
                  assetPath: AppIcons.lock,
                  size: 20,
                  color: AppColors.accentPurple,
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Text(
                    'Your exported data is encrypted and will be available for download for 7 days.',
                    style: AppTypography.caption.copyWith(color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    required _ExportFormat format,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.spacingSM),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isSelected ? AppColors.accentPurple : borderColor,
          width: isSelected ? 2 : 1,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentPurple.withValues(alpha: 0.2)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: format.iconPath,
                    size: 24,
                    color: isSelected
                        ? AppColors.accentPurple
                        : secondaryTextColor,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.name,
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      format.description,
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
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

  Widget _buildDataItem(String text, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacingXS),
      child: Row(
        children: [
          AppSvgIcon(
            assetPath: AppIcons.check,
            size: 16,
            color: AppColors.onlineGreen,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: AppText(
              text,
              style: AppTypography.body.copyWith(color: textColor),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
