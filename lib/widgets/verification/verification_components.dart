import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import '../../features/profile/data/models/profile_verification.dart';
import '../../core/responsive/responsive.dart';

/// Reusable verification UI components.
class VerificationScoreRing extends StatelessWidget {
  final int score;
  final double size;

  const VerificationScoreRing({
    super.key,
    required this.score,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.15);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreRingPainter(
          score: score,
          trackColor: muted,
          progressColor: primary,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '/100',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final int score;
  final Color trackColor;
  final Color progressColor;

  _ScoreRingPainter({
    required this.score,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = (score.clamp(0, 100) / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

/// Pill badge showing verification tier.
class VerificationBadgeChip extends StatelessWidget {
  final String badge;
  final bool compact;

  const VerificationBadgeChip({
    super.key,
    required this.badge,
    this.compact = false,
  });

  Color _badgeColor(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    switch (badge) {
      case 'Fully Verified':
        return AppColors.accentYellow;
      case 'Highly Verified':
      case 'Verified':
      case 'Photo Verified':
        return primary;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (badge == 'Unverified') return const SizedBox.shrink();

    final color = _badgeColor(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.spacingSM : AppSpacing.spacingMD,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(
            assetPath: AppIcons.shieldTick,
            size: compact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: AppSpacing.spacingXS),
          AppText(
            badge,
            style: (compact
                    ? theme.textTheme.labelSmall
                    : theme.textTheme.labelMedium)
                ?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// Three mini dots for photo / id / video verification status.
class VerificationStatusRow extends StatelessWidget {
  final bool photoVerified;
  final bool idVerified;
  final bool videoVerified;

  const VerificationStatusRow({
    super.key,
    required this.photoVerified,
    required this.idVerified,
    required this.videoVerified,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);

    Widget dot(bool verified, String label) {
      return Tooltip(
        message: label,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: verified ? primary : Colors.transparent,
            border: verified ? null : Border.all(color: muted, width: 1.5),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(photoVerified, photoVerified ? 'Photo Verified' : 'Photo not verified'),
        SizedBox(width: AppSpacing.spacingXS),
        dot(idVerified, idVerified ? 'ID Verified' : 'ID not verified'),
        SizedBox(width: AppSpacing.spacingXS),
        dot(videoVerified, videoVerified ? 'Video Verified' : 'Video not verified'),
      ],
    );
  }
}

/// History list item card.
class VerificationHistoryCard extends StatelessWidget {
  final VerificationHistoryItem item;

  const VerificationHistoryCard({super.key, required this.item});

  String _iconForType(String type) {
    return switch (type) {
      'id' => AppIcons.document,
      'video' => AppIcons.video,
      _ => AppIcons.camera,
    };
  }

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    return switch (item.status) {
      'approved' => AppColors.feedbackSuccess,
      'rejected' => theme.colorScheme.error,
      _ => AppColors.feedbackWarning,
    };
  }

  String _statusIcon(String status) {
    return switch (status) {
      'approved' => AppIcons.checkCircle,
      'rejected' => AppIcons.close,
      _ => AppIcons.clock,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSvgIcon(
            assetPath: _iconForType(item.type),
            size: 18,
            color: statusColor,
          ),
          SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${item.typeLabel} — ${item.statusLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                ),
                if (item.submittedAt != null)
                  AppText(
                    'Submitted ${formatVerificationTimeAgo(item.submittedAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    maxLines: 1,
                  ),
                if (item.adminNotes != null && item.status == 'rejected')
                  AppText(
                    'Reason: ${item.adminNotes}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 3,
                  ),
              ],
            ),
          ),
          AppSvgIcon(
            assetPath: _statusIcon(item.status),
            size: 16,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}

String formatVerificationTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${time.day}/${time.month}/${time.year}';
}

Color verificationScoreTint(BuildContext context, int score) {
  final theme = Theme.of(context);
  if (score == 0) {
    return theme.colorScheme.onSurface.withValues(alpha: 0.3);
  }
  if (score >= 100) return AppColors.accentYellow;
  if (score >= 70) return theme.colorScheme.primary;
  if (score >= 30) {
    return theme.colorScheme.primary.withValues(alpha: 0.6);
  }
  return theme.colorScheme.onSurface.withValues(alpha: 0.3);
}
