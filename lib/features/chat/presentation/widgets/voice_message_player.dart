import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/app_icons.dart';
import '../../utils/voice_waveform_layout.dart';
import '../../utils/chat_voice_bubble_layout.dart';
import '../../utils/chat_media_playback.dart';
import '../../../../widgets/chat/voice_waveform_bars.dart';

/// Voice message bubble with animated waveform and playback progress.
class VoiceMessagePlayer extends StatefulWidget {
  final String mediaUrl;
  final int? durationSeconds;
  final bool isSent;
  final VoidCallback? onListened;

  const VoiceMessagePlayer({
    super.key,
    required this.mediaUrl,
    this.durationSeconds,
    this.isSent = false,
    this.onListened,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _playerSubs = [];
  final _positionGate = ChatVoicePositionGate();
  Duration? _queuedPosition;
  bool _isPlaying = false;
  bool _notifiedListen = false;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _ownInterrupt = 0;

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    _playerSubs.add(
      _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        _positionGate.reset();
        _queuedPosition = null;
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }),
    );
    _playerSubs.add(
      _player.onPositionChanged.listen((position) {
        if (!mounted) return;
        _setPosition(position);
      }),
    );
    _playerSubs.add(
      _player.onDurationChanged.listen((duration) {
        if (!mounted || duration.inMilliseconds <= 0) return;
        setState(() => _duration = duration);
      }),
    );
    ChatMediaPlayback.interruptToken.addListener(_onMediaInterrupt);
  }

  @override
  void dispose() {
    ChatMediaPlayback.interruptToken.removeListener(_onMediaInterrupt);
    for (final sub in _playerSubs) {
      unawaited(sub.cancel());
    }
    unawaited(_player.stop());
    unawaited(_player.dispose());
    super.dispose();
  }

  void _onMediaInterrupt() {
    if (!mounted || !_isPlaying) return;
    if (ChatMediaPlayback.interruptToken.value == _ownInterrupt) return;
    unawaited(_player.pause());
    _flushPosition();
    setState(() => _isPlaying = false);
  }

  Future<void> _togglePlay() async {
    AppHaptics.light();

    if (_isPlaying) {
      await _player.pause();
      _flushPosition();
      setState(() => _isPlaying = false);
      return;
    }

    ChatMediaPlayback.interrupt();
    _ownInterrupt = ChatMediaPlayback.interruptToken.value;
    await _player.setPlaybackRate(_speed);
    await _player.play(UrlSource(widget.mediaUrl));
    setState(() => _isPlaying = true);
    if (!widget.isSent && !_notifiedListen) {
      _notifiedListen = true;
      widget.onListened?.call();
    }
  }

  void _setPosition(Duration position, {bool force = false}) {
    if (!force && !_positionGate.allow(DateTime.now())) {
      _queuedPosition = position;
      return;
    }
    _queuedPosition = null;
    if (!mounted || _position == position) return;
    setState(() => _position = position);
  }

  void _flushPosition() {
    final queued = _queuedPosition;
    if (queued == null) return;
    _positionGate.reset();
    _setPosition(queued, force: true);
  }

  Future<void> _cycleSpeed() async {
    AppHaptics.selection();

    setState(() => _speed = ChatVoiceBubbleLayout.nextSpeed(_speed));
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

  String _speedLabel(double speed) => ChatVoiceBubbleLayout.speedLabel(speed);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        widget.isSent ? theme.colorScheme.onPrimary : AppColors.accentPurple;
    final mutedAccent = accent.withValues(alpha: 0.72);
    final playButtonFill = widget.isSent
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.22)
        : AppColors.accentPurple.withValues(alpha: 0.14);
    final speedChipFill = widget.isSent
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.16)
        : AppColors.accentPurple.withValues(alpha: 0.1);

    final displayDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: widget.durationSeconds ?? 0);
    final totalLabel = _formatDuration(displayDuration);
    final timeLabel = _isPlaying
        ? '${_formatDuration(_position)} / $totalLabel'
        : totalLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = ResponsiveGrid.chatBubbleMaxWidth(
          context,
          fraction: 0.72,
        );
        final width = ChatVoiceBubbleLayout.width(
          durationSeconds: displayDuration.inSeconds,
          maxWidth: cap,
        );

        return SizedBox(
          width: width,
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
                      duration: AppAnimations.animationsEnabled(context)
                          ? AppAnimations.feedbackShort
                          : Duration.zero,
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
                  progress: _progress,
                ),
                const SizedBox(height: AppSpacing.spacingSM),
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        timeLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: mutedAccent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                        maxLines: 1,
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
      },
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
