// Screen: ProfileExportScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../widgets/navbar/app_bar_custom.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/divider_custom.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../../widgets/modals/alert_dialog_custom.dart';

/// Profile export screen - Export profile data
class ProfileExportScreen extends ConsumerStatefulWidget {
  const ProfileExportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileExportScreen> createState() => _ProfileExportScreenState();
}

class _ProfileExportScreenState extends ConsumerState<ProfileExportScreen> {
  bool _isExporting = false;
  String? _lastExportDate;
  List<String> _selectedFormats = ['JSON'];

  final List<Map<String, dynamic>> _exportFormats = [
    {
      'id': 'JSON',
      'name': 'JSON',
      'description': 'Machine-readable format',
      'icon': Icons.code,
    },
    {
      'id': 'PDF',
      'name': 'PDF',
      'description': 'Printable document',
      'icon': Icons.picture_as_pdf,
    },
    {
      'id': 'CSV',
      'name': 'CSV',
      'description': 'Spreadsheet format',
      'icon': Icons.table_chart,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLastExport();
  }

  Future<void> _loadLastExport() async {
    // TODO: Load last export date from API
    setState(() {
      _lastExportDate = null; // No previous export
    });
  }

  Future<void> _exportProfile() async {
    if (_selectedFormats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one format')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // TODO: Export profile via API
      // POST /api/profile/export
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _lastExportDate = DateTime.now().toIso8601String();
        });
        AlertDialogCustom.show(
          context,
          title: 'Export Complete',
          message: 'Your profile data has been exported successfully!',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Export Profile',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          SectionHeader(
            title: 'Export Your Data',
            icon: Icons.download,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Download a copy of your profile data in your preferred format',
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Export formats
          SectionHeader(
            title: 'Export Formats',
            icon: Icons.format_align_left,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          ..._exportFormats.map((format) {
            final isSelected = _selectedFormats.contains(format['id']);
            return _buildFormatOption(
              format: format,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFormats.remove(format['id']);
                  } else {
                    _selectedFormats.add(format['id']);
                  }
                });
              },
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
            );
          }),
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Data included
          SectionHeader(
            title: 'Data Included',
            icon: Icons.info,
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
          DividerCustom(),
          SizedBox(height: AppSpacing.spacingLG),

          // Last export
          if (_lastExportDate != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                border: Border.all(
                  color: AppColors.onlineGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
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
          GradientButton(
            text: _isExporting ? 'Exporting...' : 'Export Profile Data',
            onPressed: _isExporting ? null : _exportProfile,
            isLoading: _isExporting,
            isFullWidth: true,
            icon: Icons.download,
          ),
          SizedBox(height: AppSpacing.spacingLG),

          // Privacy note
          Container(
            padding: EdgeInsets.all(AppSpacing.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.radiusMD),
              border: Border.all(
                color: AppColors.accentPurple.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.accentPurple,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.spacingMD),
                Expanded(
                  child: Text(
                    'Your exported data is encrypted and will be available for download for 7 days.',
                    style: AppTypography.caption.copyWith(
                      color: textColor,
                    ),
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
    required Map<String, dynamic> format,
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
          color: isSelected
              ? AppColors.accentPurple
              : borderColor,
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
                      ? AppColors.accentPurple.withOpacity(0.2)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                ),
                child: Icon(
                  format['icon'],
                  color: isSelected
                      ? AppColors.accentPurple
                      : secondaryTextColor,
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format['name'],
                      style: AppTypography.body.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingXS),
                    Text(
                      format['description'],
                      style: AppTypography.caption.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
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
          Icon(
            Icons.check,
            size: 16,
            color: AppColors.onlineGreen,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Text(
            text,
            style: AppTypography.body.copyWith(color: textColor),
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
