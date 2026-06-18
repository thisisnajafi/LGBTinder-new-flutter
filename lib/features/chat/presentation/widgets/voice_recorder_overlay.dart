import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/widgets/app_action_bottom_sheet.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../providers/chat_providers.dart';

/// Hold-to-record voice capture overlay for chat.
class VoiceRecorderOverlay extends ConsumerStatefulWidget {
  final int receiverId;
  final int? conversationId;
  final VoidCallback onClose;
  final void Function(String errorMessage)? onError;

  const VoiceRecorderOverlay({
    super.key,
    required this.receiverId,
    this.conversationId,
    required this.onClose,
    this.onError,
  });

  static Future<void> show(
    BuildContext context, {
    required int receiverId,
    int? conversationId,
  }) {
    return AppActionBottomSheet.show<void>(
      context: context,
      showCancel: false,
      body: VoiceRecorderOverlay(
        receiverId: receiverId,
        conversationId: conversationId,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  ConsumerState<VoiceRecorderOverlay> createState() => _VoiceRecorderOverlayState();
}

class _VoiceRecorderOverlayState extends ConsumerState<VoiceRecorderOverlay> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSending = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _filePath;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isSending) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      widget.onError?.call('Microphone permission required');
      return;
    }

    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _filePath!);

    setState(() {
      _isRecording = true;
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= 300) {
        unawaited(_stopAndSend());
      }
    });
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    widget.onClose();
  }

  Future<void> _stopAndSend() async {
    if (_isSending) return;
    _timer?.cancel();

    if (!await _recorder.isRecording()) {
      widget.onClose();
      return;
    }

    setState(() {
      _isRecording = false;
      _isSending = true;
    });

    final path = await _recorder.stop();
    final filePath = path ?? _filePath;
    if (filePath == null || !File(filePath).existsSync()) {
      widget.onError?.call('Recording failed');
      widget.onClose();
      return;
    }

    final duration = _elapsedSeconds > 0 ? _elapsedSeconds : 1;

    try {
      final chatService = ref.read(chatServiceProvider);
      if (widget.conversationId != null && widget.conversationId! > 0) {
        final upload = await chatService.uploadChatVoice(
          widget.conversationId!,
          File(filePath),
          duration,
        );
        await chatService.sendMessage(
          widget.receiverId,
          '',
          messageType: 'voice',
          mediaPath: upload['media_path']?.toString(),
          mediaDuration: (upload['media_duration'] as num?)?.toInt() ?? duration,
        );
      } else {
        await chatService.sendMessage(
          widget.receiverId,
          '',
          messageType: 'voice',
          mediaFile: File(filePath),
          mediaDuration: duration,
        );
      }
      if (mounted) widget.onClose();
    } catch (e) {
      widget.onError?.call('Failed to send voice message');
      if (mounted) widget.onClose();
    }
  }

  String _formatElapsed(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBottomSheetCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isSending
                  ? 'Sending voice message...'
                  : (_isRecording ? 'Recording… release to send' : 'Hold to record'),
              style: AppTypography.body.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.spacingMD),
            GestureDetector(
              onLongPressStart: (_) => unawaited(_startRecording()),
              onLongPressEnd: (_) => unawaited(_stopAndSend()),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? AppColors.feedbackError
                      : AppColors.primaryLight,
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: AppIcons.microphone,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacingSM),
            if (_isRecording)
              Text(
                _formatElapsed(_elapsedSeconds),
                style: AppTypography.h3.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
            const SizedBox(height: AppSpacing.spacingMD),
            TextButton(
              onPressed: _isSending ? null : _cancelRecording,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
