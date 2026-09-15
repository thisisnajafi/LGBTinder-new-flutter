// Screen: ReportUserScreen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cache_invalidator.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/widgets/app_list_view.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/premium/premium_design_system.dart';
import '../../../../shared/models/api_error.dart';
import '../../../../shared/services/error_handler_service.dart';
import '../../../../widgets/buttons/gradient_button.dart';
import '../../data/models/report.dart';
import '../../providers/user_actions_providers.dart';

/// Report user screen - Allows users to report other users
class ReportUserScreen extends ConsumerStatefulWidget {
  final int userId;

  const ReportUserScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _selectedReason = ValueNotifier<String?>(null);
  final _isSubmitting = ValueNotifier<bool>(false);

  static const _reportReasons = [
    'spam',
    'fake_profile',
    'inappropriate_content',
    'harassment',
    'scam',
    'underage',
    'other',
  ];

  static const _reasonLabels = {
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
    _selectedReason.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReason.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    _isSubmitting.value = true;

    try {
      final userActionsService = ref.read(userActionsServiceProvider);
      await userActionsService.reportUser(
        ReportUserRequest(
          reportedUserId: widget.userId,
          reason: _selectedReason.value!,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        ),
      );
      await ref
          .read(cacheInvalidatorProvider)
          .purgeProfile(widget.userId.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted successfully. Thank you for helping keep our community safe.',
            ),
            backgroundColor: AppColors.onlineGreen,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } on ApiError catch (e) {
      if (mounted) {
        _isSubmitting.value = false;
        ErrorHandlerService.showErrorSnackBar(
          context,
          e,
          customMessage: 'Failed to submit report',
        );
      }
    } catch (e) {
      if (mounted) {
        _isSubmitting.value = false;
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
    final backgroundColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    const introCount = 1;
    const trailingCount = 2;
    final itemCount = introCount + _reportReasons.length + trailingCount;

    return AppPageScaffold(
      title: 'Report User',
      showBackButton: true,
      backgroundColor: backgroundColor,
      body: Form(
        key: _formKey,
        child: AppListView.builder(
          physics: AppScroll.bouncing,
          padding: const EdgeInsets.all(AppSpacing.spacingLG),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ReportIntro(
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              );
            }
            final reasonIndex = index - introCount;
            if (reasonIndex < _reportReasons.length) {
              final reason = _reportReasons[reasonIndex];
              return _ReportReasonTile(
                reason: reason,
                label: _reasonLabels[reason] ?? reason,
                selectedReason: _selectedReason,
                textColor: textColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
              );
            }
            if (index == itemCount - 2) {
              return _ReportDetailsField(
                controller: _descriptionController,
                textColor: textColor,
              );
            }
            return ValueListenableBuilder<bool>(
              valueListenable: _isSubmitting,
              builder: (context, submitting, _) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.spacingLG),
                  child: GradientButton(
                    text: 'Submit Report',
                    onPressed: submitting ? null : _submitReport,
                    isFullWidth: true,
                    isLoading: submitting,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReportIntro extends StatelessWidget {
  const _ReportIntro({
    required this.textColor,
    required this.secondaryTextColor,
  });

  final Color textColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Why are you reporting this user?',
          style: AppTypography.h3.copyWith(color: textColor),
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.spacingMD),
        AppText(
          'Your report helps us keep the community safe. All reports are reviewed by our team.',
          style: AppTypography.body.copyWith(color: secondaryTextColor),
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.spacingXXL),
        Text(
          'Reason',
          style: AppTypography.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spacingSM),
      ],
    );
  }
}

class _ReportReasonTile extends StatelessWidget {
  const _ReportReasonTile({
    required this.reason,
    required this.label,
    required this.selectedReason,
    required this.textColor,
    required this.surfaceColor,
    required this.borderColor,
  });

  final String reason;
  final String label;
  final ValueNotifier<String?> selectedReason;
  final Color textColor;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedReason,
      builder: (context, selected, _) {
        final isSelected = selected == reason;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.spacingSM),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentPurple.withValues(alpha: 0.1)
                : surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.radiusMD),
            border: Border.all(
              color: isSelected ? AppColors.accentPurple : borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () => selectedReason.value = reason,
            title: AppText(
              label,
              style: AppTypography.body.copyWith(color: textColor),
              maxLines: 2,
            ),
            leading: AppSvgIcon(
              assetPath: isSelected ? AppIcons.checkCircle : AppIcons.addCircle,
              size: 22,
              color: isSelected
                  ? AppColors.accentPurple
                  : textColor.withValues(alpha: 0.45),
            ),
          ),
        );
      },
    );
  }
}

class _ReportDetailsField extends StatelessWidget {
  const _ReportDetailsField({
    required this.controller,
    required this.textColor,
  });

  final TextEditingController controller;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details (Optional)',
            style: AppTypography.body.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.spacingSM),
          PremiumTextField(
            controller: controller,
            hintText: 'Provide any additional information...',
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}
