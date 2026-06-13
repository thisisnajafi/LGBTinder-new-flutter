import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../widgets/chat/voice_waveform_bars.dart';

/// Voice message bubble with animated waveform and playback progress.
class VoiceMessagePlayer extends StatefulWidget {
  final String mediaUrl;
  final int? durationSeconds;
  final bool isSent;

  const VoiceMessagePlayer({
    super.key,
    required this.mediaUrl,
    this.durationSeconds,
    this.isSent = false,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
    _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _player.onDurationChanged.listen((duration) {
      if (!mounted || duration.inMilliseconds <= 0) return;
      setState(() => _duration = duration);
    });
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _togglePlay() async {
    AppHaptics.light();

    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    await _player.setPlaybackRate(_speed);
    await _player.play(UrlSource(widget.mediaUrl));
    setState(() => _isPlaying = true);
  }

  Future<void> _cycleSpeed() async {
    AppHaptics.selection();

    setState(() {
      if (_speed == 1.0) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else {
        _speed = 1.0;
      }
    });
    if (_isPlaying) {
      await _player.setPlaybackRate(_speed);
    }
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String _speedLabel(double speed) {
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()}x';
    }
    return '${speed}x';
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isSent ? Colors.white : AppColors.accentPurple;
    final mutedAccent = accent.withValues(alpha: 0.72);
    final playButtonFill = widget.isSent
        ? Colors.white.withValues(alpha: 0.22)
        : AppColors.accentPurple.withValues(alpha: 0.14);
    final speedChipFill = widget.isSent
        ? Colors.white.withValues(alpha: 0.16)
        : AppColors.accentPurple.withValues(alpha: 0.1);

    final displayDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: widget.durationSeconds ?? 0);
    final totalLabel = _formatDuration(displayDuration);
    final timeLabel = _isPlaying
        ? '${_formatDuration(_position)} / $totalLabel'
        : totalLabel;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 236, maxWidth: 280),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: _isPlaying ? 'Pause voice message' : 'Play voice message',
            button: true,
            child: Material(
              color: playButtonFill,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: accent.withValues(alpha: 0.12),
                highlightColor: accent.withValues(alpha: 0.08),
                onTap: _togglePlay,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppAnimations.feedbackShort,
                      switchInCurve: AppAnimations.curveDefault,
                      switchOutCurve: AppAnimations.curveDefault,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: AppSvgIcon(
                        key: ValueKey(_isPlaying),
                        assetPath: _isPlaying ? AppIcons.pause : AppIcons.play,
                        size: 22,
                        color: accent,
                      ),
                    ),
                  ),
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
                  active: _isPlaying,
                  color: accent,
                  height: 28,
                  barCount: 24,
                  progress: _progress,
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        timeLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: mutedAccent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacingSM),
                    _PlaybackSpeedChip(
                      label: _speedLabel(_speed),
                      foreground: accent,
                      background: speedChipFill,
                      onTap: _cycleSpeed,
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

class _PlaybackSpeedChip extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  const _PlaybackSpeedChip({
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Playback speed $label. Tap to change.',
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.radiusRound),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusRound),
          splashColor: foreground.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingSM + 2,
              vertical: AppSpacing.spacingXS + 1,
            ),
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
