// Widget: UploadProgressIndicator
// File upload progress
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Upload progress indicator widget
/// Shows file upload progress with percentage
class UploadProgressIndicator extends ConsumerWidget {
  final double progress; // 0.0 to 1.0
  final String? fileName;
  final VoidCallback? onCancel;

  const UploadProgressIndicator({
    Key? key,
    required this.progress,
    this.fileName,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload,
                color: AppColors.accentPurple,
                size: 20,
              ),
              SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: Text(
                  fileName ?? 'Uploading...',
                  style: AppTypography.body.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCancel != null)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: secondaryTextColor,
                  ),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingSM),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
          ),
          SizedBox(height: AppSpacing.spacingXS),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: AppTypography.caption.copyWith(color: secondaryTextColor),
          ),
        ],
      ),
    );
  }
}
