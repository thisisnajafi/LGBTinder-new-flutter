import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/typography.dart';
import '../../features/chat/utils/chat_voice_bubble_layout.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = ResponsiveGrid.chatBubbleMaxWidth(
          context,
          fraction: 0.72,
        );
        final scaled = ChatVoiceBubbleLayout.width(
          durationSeconds: durationSeconds,
          maxWidth: cap,
        );
        final width = math.min(cap, math.max(scaled, 220));

        return SizedBox(
          width: width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: color.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacingSM),
              Expanded(
                child: VoiceWaveformBars(
                  active: true,
                  color: color,
                  height: 22,
                ),
              ),
              if (durationSeconds != null) ...[
                const SizedBox(width: AppSpacing.spacingSM),
                Text(
                  _formatDuration(durationSeconds!),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: AppTypography.labelSmall.copyWith(
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.spacingSM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacingSM,
                  vertical: AppSpacing.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: chipFill,
                  borderRadius: BorderRadius.circular(AppRadius.radiusRound),
                ),
                child: Text(
                  'Sending',
                  maxLines: 1,
                  softWrap: false,
                  style: AppTypography.labelSmall.copyWith(
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
