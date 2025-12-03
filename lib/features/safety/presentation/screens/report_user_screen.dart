// Screen: ReportUserScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../widgets/navbar/app_bar_custom.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../providers/user_actions_providers.dart';
import '../../data/models/report.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';

/// Report user screen - Allows users to report other users
class ReportUserScreen extends ConsumerStatefulWidget {
  final int userId;

  const ReportUserScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _reportReasons = [
    'spam',
    'fake_profile',
    'inappropriate_content',
    'harassment',
    'scam',
    'underage',
    'other',
  ];

  final Map<String, String> _reasonLabels = {
    'spam': 'Spam',
    'fake_profile': 'Fake Profile',
    'inappropriate_content': 'Inappropriate Content',
    'harassment': 'Harassment',
    'scam': 'Scam',
    'underage': 'Underage',
    'other': 'Other',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userActionsService = ref.read(userActionsServiceProvider);
      await userActionsService.reportUser(
        ReportUserRequest(
          reportedUserId: widget.userId,
          reason: _selectedReason!,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Thank you for helping keep our community safe.'),
            backgroundColor: AppColors.onlineGreen,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to submit report',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ErrorHandlerService.handleError(
          context,
          e,
          customMessage: 'Failed to submit report',
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBarCustom(
        title: 'Report User',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(AppSpacing.spacingLG),
            children: [
              // Header
              Text(
                'Why are you reporting this user?',
                style: AppTypography.h3.copyWith(color: textColor),
              ),
              SizedBox(height: AppSpacing.spacingMD),
              Text(
                'Your report helps us keep the community safe. All reports are reviewed by our team.',
                style: AppTypography.body.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              SizedBox(height: AppSpacing.spacingXXL),

              // Reason selection
              Text(
                'Reason',
                style: AppTypography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.spacingSM),
              ..._reportReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return Container(
                  margin: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPurple.withOpacity(0.1)
                        : surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPurple
                          : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      _reasonLabels[reason] ?? reason,
                      style: AppTypography.body.copyWith(color: textColor),
                    ),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                    activeColor: AppColors.accentPurple,
                  ),
                );
              }),
              SizedBox(height: AppSpacing.spacingXXL),

              // Description
              Text(
                'Additional Details (Optional)',
                style: AppTypography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.spacingSM),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Provide any additional information...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radiusMD),
                    borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                  ),
                  filled: true,
                  fillColor: surfaceColor,
                ),
                style: AppTypography.body.copyWith(color: textColor),
              ),
              SizedBox(height: AppSpacing.spacingXXL),

              // Submit button
              GradientButton(
                text: 'Submit Report',
                onPressed: _isSubmitting ? null : _submitReport,
                isFullWidth: true,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
