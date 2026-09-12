import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import 'voice_waveform_bars.dart';

/// In-composer recording chrome: 30-bar waveform, lock hint, discard (CHAT-INPUT-003).
class ChatVoiceRecordBar extends StatelessWidget {
  static const double minTouch = 44;
  static const Key barKey = ValueKey('chat-voice-record-bar');
  static const Key discardKey = ValueKey('chat-voice-discard');
  static const Key lockedKey = ValueKey('chat-voice-locked');
  static const Key lockHintKey = ValueKey('chat-voice-lock-hint');

  final int seconds;
  final bool locked;
  final bool compact;
  final VoidCallback onDiscard;

  const ChatVoiceRecordBar({
    super.key,
    required this.seconds,
    required this.locked,
    required this.onDiscard,
    this.compact = false,
  });

  static String formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      key: locked ? lockedKey : barKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      child: Row(
        children: [
          if (locked)
            Semantics(
              button: true,
              label: 'Discard recording',
              child: InkWell(
                key: discardKey,
                onTap: onDiscard,
                borderRadius: BorderRadius.circular(AppSpacing.spacingMD),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: minTouch,
                    minHeight: minTouch,
                  ),
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: AppIcons.delete,
                      size: 22,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          if (locked) const SizedBox(width: AppSpacing.spacingXS),
          PulsingRecordDot(color: AppColors.feedbackError),
          const SizedBox(width: AppSpacing.spacingSM),
          AppText(
            formatDuration(seconds),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
          ),
          const SizedBox(width: AppSpacing.spacingMD),
          Expanded(
            child: VoiceWaveformBars(
              active: true,
              color: theme.colorScheme.primary,
              height: 20,
              barCount: AppAnimations.chatVoiceRecordBars,
            ),
          ),
          if (!locked) ...[
            const SizedBox(width: AppSpacing.spacingSM),
            Semantics(
              label: 'Slide up to lock',
              child: AppSvgIcon(
                key: lockHintKey,
                assetPath: AppIcons.lock,
                size: 18,
                color: secondary,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AppSpacing.spacingXS),
              AppText(
                '< Slide to cancel',
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(color: secondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
