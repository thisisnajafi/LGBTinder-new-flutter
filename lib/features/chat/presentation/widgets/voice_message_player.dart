import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
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

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isSent ? Colors.white : AppColors.accentPurple;
    final textColor = widget.isSent ? Colors.white : AppColors.textPrimaryDark;
    final displayDuration =
        _duration.inMilliseconds > 0 ? _duration : Duration(seconds: widget.durationSeconds ?? 0);
    final timeLabel = _isPlaying
        ? _formatDuration(_position)
        : _formatDuration(displayDuration);

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Semantics(
            label: _isPlaying ? 'Pause voice message' : 'Play voice message',
            button: true,
            child: Material(
              color: iconColor.withValues(alpha: 0.15),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _togglePlay,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: AppSvgIcon(
                      key: ValueKey(_isPlaying),
                      assetPath: _isPlaying ? AppIcons.pause : AppIcons.play,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VoiceWaveformBars(
                  active: _isPlaying,
                  color: iconColor,
                  height: 22,
                  barCount: 14,
                  progress: _progress,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: textColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _cycleSpeed,
                      style: TextButton.styleFrom(
                        foregroundColor: textColor,
                        minimumSize: const Size(36, 28),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('${_speed}x'),
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
