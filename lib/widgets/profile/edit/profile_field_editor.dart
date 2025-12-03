// Widget: ProfileFieldEditor
// Profile field editor
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/spacing_constants.dart';
import '../../../core/theme/border_radius_constants.dart';
import '../../buttons/gradient_button.dart';

/// Profile field editor widget
/// Generic editor for a single profile field
class ProfileFieldEditor extends ConsumerStatefulWidget {
  final String label;
  final String? initialValue;
  final String? hintText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onSave;
  final VoidCallback? onCancel;

  const ProfileFieldEditor({
    Key? key,
    required this.label,
    this.initialValue,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onSave,
    this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<ProfileFieldEditor> createState() => _ProfileFieldEditorState();
}

class _ProfileFieldEditorState extends ConsumerState<ProfileFieldEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppTypography.h3.copyWith(color: textColor),
          ),
          SizedBox(height: AppSpacing.spacingMD),
          TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            style: AppTypography.body.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.body.copyWith(color: secondaryTextColor),
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceElevatedLight,
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
              contentPadding: EdgeInsets.all(AppSpacing.spacingMD),
            ),
          ),
          SizedBox(height: AppSpacing.spacingLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Cancel',
                    style: AppTypography.button.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              SizedBox(width: AppSpacing.spacingMD),
              GradientButton(
                text: 'Save',
                onPressed: () => widget.onSave?.call(_controller.text),
                isFullWidth: false,
                height: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
