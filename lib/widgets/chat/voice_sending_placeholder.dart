import 'package:flutter/material.dart';

import '../../core/theme/border_radius_constants.dart';
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
    final chipFill = color.withValues(alpha: isSent ? 0.16 : 0.1);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 236, maxWidth: 280),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                VoiceWaveformBars(
                  active: true,
                  color: color,
                  height: 28,
                  barCount: 24,
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Row(
                  children: [
                    if (durationSeconds != null)
                      Expanded(
                        child: Text(
                          _formatDuration(durationSeconds!),
                          style: AppTypography.labelSmall.copyWith(
                            color: color.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacingSM + 2,
                        vertical: AppSpacing.spacingXS + 1,
                      ),
                      decoration: BoxDecoration(
                        color: chipFill,
                        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSvgIcon(
                            assetPath: AppIcons.microphone,
                            size: 12,
                            color: color.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: AppSpacing.spacingXS),
                          Text(
                            'Sending',
                            style: AppTypography.labelSmall.copyWith(
                              color: color.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
