import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import 'verification_components.dart';

enum VerificationType { photo, id, video }

enum VerificationCardStatus { notStarted, pending, approved, rejected }

extension VerificationTypeX on VerificationType {
  String get label => switch (this) {
        VerificationType.photo => 'Photo Verification',
        VerificationType.id => 'ID Verification',
        VerificationType.video => 'Video Verification',
      };

  String get uploadLabel => switch (this) {
        VerificationType.photo => 'Photo',
        VerificationType.id => 'ID',
        VerificationType.video => 'Video',
      };

  int get points => switch (this) {
        VerificationType.photo => 30,
        VerificationType.id => 40,
        VerificationType.video => 30,
      };

  String get iconPath => switch (this) {
        VerificationType.photo => AppIcons.camera,
        VerificationType.id => AppIcons.document,
        VerificationType.video => AppIcons.video,
      };
}

/// Card for a single verification type (photo / id / video).
class VerificationTypeCard extends StatelessWidget {
  final VerificationType type;
  final VerificationCardStatus status;
  final String? adminNotes;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int? pendingVerificationId;
  final String guidelinesText;
  final VoidCallback onUpload;
  final VoidCallback? onCancel;
  final bool isUploading;
  final double uploadProgress;

  const VerificationTypeCard({
    super.key,
    required this.type,
    required this.status,
    this.adminNotes,
    this.submittedAt,
    this.reviewedAt,
    this.pendingVerificationId,
    required this.guidelinesText,
    required this.onUpload,
    this.onCancel,
    this.isUploading = false,
    this.uploadProgress = 0,
  });

  Color _borderColor(BuildContext context) {
    final theme = Theme.of(context);
    return switch (status) {
      VerificationCardStatus.pending =>
        AppColors.feedbackWarning.withValues(alpha: 0.7),
      VerificationCardStatus.approved =>
        theme.colorScheme.primary.withValues(alpha: 0.7),
      VerificationCardStatus.rejected =>
        theme.colorScheme.error.withValues(alpha: 0.7),
      VerificationCardStatus.notStarted => theme.colorScheme.outlineVariant,
    };
  }

  double _borderWidth() => status == VerificationCardStatus.notStarted ? 0.5 : 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final surfaceVariant =
        theme.colorScheme.surfaceContainerHighest;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacingMD),
      padding: const EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor(context),
          width: _borderWidth(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          SizedBox(height: AppSpacing.spacingMD),
          _buildContent(context, muted),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (status) {
      VerificationCardStatus.approved => theme.colorScheme.primary,
      VerificationCardStatus.rejected => theme.colorScheme.error,
      VerificationCardStatus.pending => AppColors.feedbackWarning,
      VerificationCardStatus.notStarted => theme.colorScheme.onSurface,
    };

    return Row(
      children: [
        AppSvgIcon(
          assetPath: type.iconPath,
          size: 22,
          color: statusColor,
        ),
        SizedBox(width: AppSpacing.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Adds ${type.points} points',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        _StatusChip(status: status),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Color muted) {
    final theme = Theme.of(context);

    switch (status) {
      case VerificationCardStatus.pending:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (submittedAt != null)
              Text(
                'Submitted ${formatVerificationTimeAgo(submittedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            SizedBox(height: AppSpacing.spacingSM),
            if (onCancel != null)
              OutlinedButton.icon(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: AppSvgIcon(
                  assetPath: AppIcons.delete,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                label: const Text('Cancel Submission'),
              ),
          ],
        );
      case VerificationCardStatus.approved:
        return Text(
          reviewedAt != null
              ? 'Approved ${formatVerificationTimeAgo(reviewedAt!)}'
              : 'Approved',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        );
      case VerificationCardStatus.notStarted:
      case VerificationCardStatus.rejected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              guidelinesText,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (status == VerificationCardStatus.rejected &&
                adminNotes != null &&
                adminNotes!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.spacingSM),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSvgIcon(
                      assetPath: AppIcons.danger,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    SizedBox(width: AppSpacing.spacingSM),
                    Expanded(
                      child: Text(
                        adminNotes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppSpacing.spacingMD),
            FilledButton.icon(
              onPressed: isUploading ? null : onUpload,
              icon: AppSvgIcon(
                assetPath: AppIcons.upload,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
              label: Text('Upload ${type.uploadLabel}'),
            ),
            if (isUploading) ...[
              SizedBox(height: AppSpacing.spacingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: uploadProgress.clamp(0, 1),
                  minHeight: 3,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ],
          ],
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final VerificationCardStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == VerificationCardStatus.notStarted) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    late Color color;
    late String label;
    late String icon;

    switch (status) {
      case VerificationCardStatus.pending:
        color = AppColors.feedbackWarning;
        label = 'Under Review';
        icon = AppIcons.clock;
        break;
      case VerificationCardStatus.approved:
        color = theme.colorScheme.primary;
        label = 'Approved';
        icon = AppIcons.checkCircle;
        break;
      case VerificationCardStatus.rejected:
        color = theme.colorScheme.error;
        label = 'Rejected';
        icon = AppIcons.close;
        break;
      case VerificationCardStatus.notStarted:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(assetPath: icon, size: 12, color: color),
          SizedBox(width: AppSpacing.spacingXS),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
