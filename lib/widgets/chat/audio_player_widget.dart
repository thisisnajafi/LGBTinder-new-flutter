// Widget: AudioPlayerWidget
// Audio message player with controls
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Audio player widget
/// Plays audio messages with play/pause controls and progress indicator
class AudioPlayerWidget extends ConsumerStatefulWidget {
  final String audioUrl;
  final Duration? duration;
  final Color? backgroundColor;
  final bool isSent;

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    this.duration,
    this.backgroundColor,
    this.isSent = false,
  }) : super(key: key);

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.duration ?? const Duration(seconds: 0);
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      // TODO: Implement actual audio playback
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (widget.isSent
            ? AppColors.accentPurple
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight));
    final textColor = widget.isSent
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingMD),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isSent
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.accentPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.spacingMD),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _totalDuration.inMilliseconds > 0
                      ? _currentPosition.inMilliseconds /
                          _totalDuration.inMilliseconds
                      : 0.0,
                  backgroundColor: textColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              ),
              SizedBox(height: AppSpacing.spacingXS),
              Text(
                '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                style: AppTypography.caption.copyWith(color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
