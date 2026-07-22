// Widget: CancellationReasonDialog
// Subscription cancellation dialog
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../modals/bottom_sheet_custom.dart';
import '../buttons/gradient_button.dart';
import '../../core/responsive/responsive.dart';

/// Cancellation reason dialog widget
/// Dialog for collecting cancellation reasons when user cancels subscription
class CancellationReasonDialog extends ConsumerStatefulWidget {
  final Function(String reason)? onReasonSelected;
  final VoidCallback? onCancel;

  const CancellationReasonDialog({
    Key? key,
    this.onReasonSelected,
    this.onCancel,
  }) : super(key: key);

  static Future<String?> show(
    BuildContext context, {
    Function(String reason)? onReasonSelected,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => CancellationReasonDialog(
        onReasonSelected: (reason) {
          Navigator.of(context).pop(reason);
          onReasonSelected?.call(reason);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  ConsumerState<CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState
    extends ConsumerState<CancellationReasonDialog> {
  String? _selectedReason;

  final List<String> _reasons = [
    'Too expensive',
    'Not using it enough',
    'Found someone',
    'Technical issues',
    'Privacy concerns',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Container(
        padding: EdgeInsets.all(AppSpacing.spacingXL),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.radiusMD),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Why are you canceling?',
              style: AppTypography.h2.copyWith(color: textColor),
              maxLines: 2,
            ),
            SizedBox(height: AppSpacing.spacingMD),
            AppText(
              'Your feedback helps us improve',
              style: AppTypography.body.copyWith(color: secondaryTextColor),
              maxLines: 3,
            ),
            SizedBox(height: AppSpacing.spacingLG),
            ..._reasons.map((reason) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.spacingSM),
                child: RadioListTile<String>(
                  title: AppText(
                    reason,
                    style: AppTypography.body.copyWith(color: textColor),
                    maxLines: 2,
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
            SizedBox(height: AppSpacing.spacingLG),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 320) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GradientButton(
                        text: 'Continue',
                        onPressed: _selectedReason != null
                            ? () => widget.onReasonSelected?.call(_selectedReason!)
                            : null,
                        isFullWidth: true,
                        height: 40,
                      ),
                      TextButton(
                        onPressed: widget.onCancel,
                        child: Text(
                          'Skip',
                          style: AppTypography.button.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Skip',
                    style: AppTypography.button.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.spacingMD),
                GradientButton(
                  text: 'Continue',
                  onPressed: _selectedReason != null
                      ? () => widget.onReasonSelected?.call(_selectedReason!)
                      : null,
                  isFullWidth: false,
                  height: 40,
                ),
              ],
            );
              },
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
