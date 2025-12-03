// Screen: ProfileTemplatesScreen
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

/// Profile templates screen - Profile template selection
class ProfileTemplatesScreen extends ConsumerStatefulWidget {
  const ProfileTemplatesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileTemplatesScreen> createState() => _ProfileTemplatesScreenState();
}

class _ProfileTemplatesScreenState extends ConsumerState<ProfileTemplatesScreen> {
  bool _isLoading = false;
  String? _selectedTemplateId;
  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load templates from API
      // GET /api/profile/templates
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _templates = [
            {
              'id': '1',
              'name': 'Classic',
              'description': 'Traditional profile layout',
              'preview_image': null,
              'is_premium': false,
            },
            {
              'id': '2',
              'name': 'Modern',
              'description': 'Clean and minimalist design',
              'preview_image': null,
              'is_premium': false,
            },
            {
              'id': '3',
              'name': 'Creative',
              'description': 'Bold and expressive style',
              'preview_image': null,
              'is_premium': true,
            },
            {
              'id': '4',
              'name': 'Professional',
              'description': 'Business-focused layout',
              'preview_image': null,
              'is_premium': true,
            },
          ];
          _selectedTemplateId = '1'; // Current template
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load templates: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyTemplate(String templateId) async {
    setState(() {
      _selectedTemplateId = templateId;
    });

    try {
      // TODO: Apply template via API
      // POST /api/profile/templates/apply
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        AlertDialogCustom.show(
          context,
          title: 'Template Applied',
          message: 'Your profile template has been updated successfully!',
          icon: Icons.check_circle,
          iconColor: AppColors.onlineGreen,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply template: $e')),
        );
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBarCustom(
          title: 'Profile Templates',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Profile Templates',
        showBackButton: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.spacingLG),
        children: [
          SectionHeader(
            title: 'Choose a Template',
            icon: Icons.palette,
          ),
          SizedBox(height: AppSpacing.spacingMD),
          Text(
            'Select a template to customize your profile appearance',
            style: AppTypography.body.copyWith(
              color: secondaryTextColor,
            ),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              final isSelected = _selectedTemplateId == template['id'];
              final isPremium = template['is_premium'] ?? false;
              return _buildTemplateCard(
                template: template,
                isSelected: isSelected,
                isPremium: isPremium,
                onTap: () => _applyTemplate(template['id']),
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required Map<String, dynamic> template,
    required bool isSelected,
    required bool isPremium,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPurple
                : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.radiusMD),
                    topRight: Radius.circular(AppRadius.radiusMD),
                  ),
                ),
                child: template['preview_image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.radiusMD),
                          topRight: Radius.circular(AppRadius.radiusMD),
                        ),
                        child: Image.network(
                          template['preview_image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderPreview();
                          },
                        ),
                      )
                    : _buildPlaceholderPreview(),
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(AppSpacing.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          template['name'] ?? 'Template',
                          style: AppTypography.body.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isPremium)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacingSM,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warningYellow,
                                AppColors.warningYellow.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.radiusSM),
                          ),
                          child: Text(
                            'Premium',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.spacingXS),
                  Text(
                    template['description'] ?? '',
                    style: AppTypography.caption.copyWith(
                      color: secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isSelected) ...[
                    SizedBox(height: AppSpacing.spacingSM),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.accentPurple,
                          size: 16,
                        ),
                        SizedBox(width: AppSpacing.spacingXS),
                        Text(
                          'Active',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPreview() {
    return Container(
      color: AppColors.accentPurple.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.person,
          size: 48,
          color: AppColors.accentPurple.withOpacity(0.5),
        ),
      ),
    );
  }
}
