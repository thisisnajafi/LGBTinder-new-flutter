import 'package:flutter/material.dart';

import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/app_icons.dart';
import 'voice_waveform_bars.dart';

/// Optimistic voice bubble shown while upload/send is in progress.
class VoiceSendingPlaceholder extends StatelessWidget {
  final int? durationSeconds;
  final bool isSent;
  final Color? foregroundColor;

  const VoiceSendingPlaceholder({
    super.key,
    this.durationSeconds,
    this.isSent = true,
    this.foregroundColor,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ??
        (isSent ? Colors.white : Theme.of(context).colorScheme.primary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: AppSpacing.spacingSM),
        VoiceWaveformBars(
          active: true,
          color: color,
          height: 20,
          barCount: 10,
        ),
        const SizedBox(width: AppSpacing.spacingSM),
        if (durationSeconds != null)
          Text(
            _formatDuration(durationSeconds!),
            style: AppTypography.body.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(width: AppSpacing.spacingXS),
        AppSvgIcon(
          assetPath: AppIcons.microphone,
          size: 16,
          color: color.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}
