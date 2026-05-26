import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';

/// Voice message bubble with play/pause and playback speed control.
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

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
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

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isSent ? Colors.white : AppColors.accentPurple;
    final textColor = widget.isSent ? Colors.white : AppColors.textPrimaryDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: _isPlaying ? 'Pause voice message' : 'Play voice message',
          button: true,
          child: IconButton(
            onPressed: _togglePlay,
            icon: AppSvgIcon(
              assetPath: _isPlaying ? AppIcons.timerPause : AppIcons.microphone2,
              size: 22,
              color: iconColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
        if (widget.durationSeconds != null)
          Text(
            _formatDuration(widget.durationSeconds!),
            style: AppTypography.body.copyWith(color: textColor),
          ),
        const SizedBox(width: AppSpacing.spacingSM),
        TextButton(
          onPressed: _cycleSpeed,
          style: TextButton.styleFrom(
            foregroundColor: textColor,
            minimumSize: const Size(44, 44),
          ),
          child: Text('${_speed}x'),
        ),
      ],
    );
  }
}
