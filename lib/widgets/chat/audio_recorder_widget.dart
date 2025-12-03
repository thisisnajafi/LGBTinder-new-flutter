// Widget: AudioRecorderWidget
// Audio recorder for voice messages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Audio recorder widget
/// Records voice messages with visual feedback
class AudioRecorderWidget extends ConsumerStatefulWidget {
  final Function(String? audioPath, Duration duration)? onRecordingComplete;
  final Function()? onCancel;

  const AudioRecorderWidget({
    Key? key,
    this.onRecordingComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends ConsumerState<AudioRecorderWidget> {
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });

    // TODO: Start actual audio recording
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
    // TODO: Stop recording and get audio path
    widget.onRecordingComplete?.call(null, _recordingDuration);
  }

  void _cancelRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
    widget.onCancel?.call();
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      padding: EdgeInsets.all(AppSpacing.spacingLG),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(
          color: isDark ? AppColors.borderMediumDark : AppColors.borderMediumLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.notificationRed,
                    shape: BoxShape.circle,
                  ),
                ),
              if (_isRecording) SizedBox(width: AppSpacing.spacingSM),
              Text(
                _formatDuration(_recordingDuration),
                style: AppTypography.h2.copyWith(color: textColor),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.spacingLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_isRecording)
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: _cancelRecording,
                ),
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.notificationRed
                        : AppColors.accentPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              if (_isRecording)
                IconButton(
                  icon: Icon(Icons.check, color: AppColors.onlineGreen),
                  onPressed: _stopRecording,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
