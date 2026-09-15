import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import 'voice_waveform_bars.dart';

/// In-composer recording chrome: 30-bar waveform, lock hint, discard (CHAT-INPUT-003).
///
/// Elapsed time ticks inside this widget so [MessageInput] does not rebuild
/// every second (PERF-COMP-MSG-013).
class ChatVoiceRecordBar extends StatefulWidget {
  static const double minTouch = 44;
  static const Key barKey = ValueKey('chat-voice-record-bar');
  static const Key discardKey = ValueKey('chat-voice-discard');
  static const Key lockedKey = ValueKey('chat-voice-locked');
  static const Key lockHintKey = ValueKey('chat-voice-lock-hint');

  /// When set, the bar shows this value (widget tests). Otherwise it ticks locally.
  final int? seconds;
  final bool locked;
  final bool compact;
  final VoidCallback onDiscard;

  const ChatVoiceRecordBar({
    super.key,
    this.seconds,
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
  State<ChatVoiceRecordBar> createState() => _ChatVoiceRecordBarState();
}

class _ChatVoiceRecordBarState extends State<ChatVoiceRecordBar> {
  Timer? _timer;
  late final ValueNotifier<int> _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = ValueNotifier(widget.seconds ?? 0);
    if (widget.seconds == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed.value++;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ChatVoiceRecordBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seconds != null && widget.seconds != _elapsed.value) {
      _elapsed.value = widget.seconds!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsed.dispose();
    super.dispose();
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
      key: widget.locked ? ChatVoiceRecordBar.lockedKey : ChatVoiceRecordBar.barKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingLG,
        vertical: AppSpacing.spacingMD,
      ),
      child: Row(
        children: [
          if (widget.locked)
            Semantics(
              button: true,
              label: 'Discard recording',
              child: InkWell(
                key: ChatVoiceRecordBar.discardKey,
                onTap: widget.onDiscard,
                borderRadius: BorderRadius.circular(AppSpacing.spacingMD),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: ChatVoiceRecordBar.minTouch,
                    minHeight: ChatVoiceRecordBar.minTouch,
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
          if (widget.locked) const SizedBox(width: AppSpacing.spacingXS),
          PulsingRecordDot(color: AppColors.feedbackError),
          const SizedBox(width: AppSpacing.spacingSM),
          ValueListenableBuilder<int>(
            valueListenable: _elapsed,
            builder: (context, seconds, _) {
              return AppText(
                ChatVoiceRecordBar.formatDuration(seconds),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              );
            },
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
          if (!widget.locked) ...[
            const SizedBox(width: AppSpacing.spacingSM),
            Semantics(
              label: 'Slide up to lock',
              child: AppSvgIcon(
                key: ChatVoiceRecordBar.lockHintKey,
                assetPath: AppIcons.lock,
                size: 18,
                color: secondary,
              ),
            ),
            if (!widget.compact) ...[
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
