import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_icons.dart';
import 'verification_video_limits.dart';

/// Front-camera recorder for video verification.
///
/// Recording cannot be submitted before 5 seconds and stops at 10 seconds.
class VerificationVideoRecordPage extends StatefulWidget {
  const VerificationVideoRecordPage({super.key});

  @override
  State<VerificationVideoRecordPage> createState() =>
      _VerificationVideoRecordPageState();
}

class _VerificationVideoRecordPageState extends State<VerificationVideoRecordPage> {
  CameraController? _camera;
  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  bool _preparing = true;
  bool _recording = false;
  bool _finishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_openCamera());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      unawaited(camera.dispose().catchError((Object _) {}));
    }
    super.dispose();
  }

  Future<void> _openCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _error = 'Camera and microphone access are required to record.';
      });
      return;
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera');
      }
      var front = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          front = camera;
          break;
        }
      }
      controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose().catchError((Object _) {});
        return;
      }
      setState(() {
        _camera = controller;
        _preparing = false;
        _error = null;
      });
    } catch (error) {
      await controller?.dispose().catchError((Object _) {});
      if (!mounted) return;
      final missingPlugin = error is MissingPluginException ||
          error.toString().contains('channel-error') ||
          error.toString().contains('MissingPluginException');
      setState(() {
        _preparing = false;
        _error = missingPlugin
            ? 'The camera is not ready yet. Fully restart the app, then try again.'
            : 'Could not open the camera. Try again.';
      });
    }
  }

  Future<void> _start() async {
    final camera = _camera;
    if (camera == null || _recording || _finishing) return;
    try {
      await camera.startVideoRecording();
      _startedAt = DateTime.now();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final started = _startedAt;
        if (started == null || !mounted) return;
        final elapsed = DateTime.now().difference(started);
        setState(() => _elapsed = elapsed);
        if (VerificationVideoLimits.mustFinish(elapsed)) {
          unawaited(_finish());
        }
      });
      if (!mounted) return;
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not start recording.');
    }
  }

  Future<void> _finish() async {
    if (_finishing || !_recording) return;
    if (!VerificationVideoLimits.canFinish(_elapsed)) return;
    final camera = _camera;
    if (camera == null) return;

    _finishing = true;
    _ticker?.cancel();
    try {
      final file = await camera.stopVideoRecording();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _finishing = false;
        _error = 'Could not save the video.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final camera = _camera;
    final canFinish = VerificationVideoLimits.canFinish(_elapsed);
    final progress = (_elapsed.inMilliseconds /
            VerificationVideoLimits.maximum.inMilliseconds)
        .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null && camera.value.isInitialized)
            CameraPreview(camera)
          else
            const ColoredBox(color: AppColors.backgroundDark),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacingLG),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        iconPath: AppIcons.close,
                        label: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Text(
                        '5–10 seconds',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_preparing)
                    const CircularProgressIndicator()
                  else if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingLG),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _preparing = true;
                          _error = null;
                        });
                        unawaited(_openCamera());
                      },
                      child: const Text('Retry'),
                    ),
                  ]
                  else ...[
                    Text(
                      VerificationVideoLimits.clock(_elapsed),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingSM),
                    Text(
                      _recording
                          ? (canFinish
                              ? 'Tap to finish. It stops at 10 seconds.'
                              : 'Keep going. Minimum is 5 seconds.')
                          : 'Look at the camera and say your username.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacingXL),
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _recording ? progress : 0,
                            strokeWidth: 4,
                            color: theme.colorScheme.primary,
                            backgroundColor: AppColors.textPrimaryDark
                                .withValues(alpha: 0.25),
                          ),
                          _RoundIconButton(
                            iconPath: _recording
                                ? AppIcons.getIconPath('stop')
                                : AppIcons.getIconPath('video'),
                            label: _recording ? 'Stop recording' : 'Start recording',
                            filled: true,
                            enabled: !_recording || canFinish,
                            onPressed: _recording ? _finish : _start,
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.spacingXXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.iconPath,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.enabled = true,
  });

  final String iconPath;
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = filled
        ? theme.colorScheme.primary
        : AppColors.textPrimaryDark.withValues(alpha: 0.2);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: enabled ? color : color.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: AppSvgIcon(
                assetPath: iconPath,
                size: 28,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
