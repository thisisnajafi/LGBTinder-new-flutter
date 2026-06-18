import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/screenshot_protection.dart';
import '../../../../core/widgets/app_action_bottom_sheet.dart';
import '../../../../features/chat/providers/chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen self-destruct photo viewer with countdown ring and screenshot protection.
class SelfDestructViewer extends ConsumerStatefulWidget {
  final int messageId;
  final int? initialRemainingSeconds;

  const SelfDestructViewer({
    super.key,
    required this.messageId,
    this.initialRemainingSeconds,
  });

  static Future<bool?> open(
    BuildContext context, {
    required int messageId,
    int? initialRemainingSeconds,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (context) => SelfDestructViewer(
          messageId: messageId,
          initialRemainingSeconds: initialRemainingSeconds,
        ),
      ),
    );
  }

  @override
  ConsumerState<SelfDestructViewer> createState() => _SelfDestructViewerState();
}

class _SelfDestructViewerState extends ConsumerState<SelfDestructViewer> {
  String? _imageUrl;
  int? _remainingSeconds;
  bool _isLoading = true;
  String? _error;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialRemainingSeconds;
    _enableScreenshotProtection();
    unawaited(_loadView());
  }

  Future<void> _enableScreenshotProtection() async {
    await ScreenshotProtection.enable();
  }

  Future<void> _disableScreenshotProtection() async {
    await ScreenshotProtection.disable();
  }
  Future<void> _loadView() async {
    try {
      final payload = await ref
          .read(chatServiceProvider)
          .viewSelfDestructMessage(widget.messageId);

      if (!mounted) return;

      setState(() {
        _imageUrl = payload['secure_media_url']?.toString();
        _remainingSeconds = payload['remaining_seconds'] as int? ??
            widget.initialRemainingSeconds;
        _isLoading = false;
      });

      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to open photo';
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_remainingSeconds == null || _remainingSeconds! <= 0) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = (_remainingSeconds ?? 1) - 1;
      });
      if ((_remainingSeconds ?? 0) <= 0) {
        timer.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(_disableScreenshotProtection());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CloseButton(color: AppColors.textPrimaryDark),
        actions: [
          if (_remainingSeconds != null && _remainingSeconds! > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.spacingMD),
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CustomPaint(
                    painter: _CountdownRingPainter(
                      progress: _remainingSeconds! / 60.0,
                      color: AppColors.primaryLight,
                    ),
                    child: Center(
                      child: Text(
                        '$_remainingSeconds',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (_error != null || _imageUrl == null) {
      return Center(
        child: Text(
          _error ?? 'Photo unavailable',
          style: AppTypography.body.copyWith(color: Colors.white70),
        ),
      );
    }

    return PhotoView(
      imageProvider: NetworkImage(_imageUrl!),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CountdownRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      6.283185307179586 * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Duration picker for self-destruct photos (5 / 10 / 30 / 60 seconds).
class SelfDestructDurationSheet extends StatelessWidget {
  final void Function(int seconds) onSelected;

  const SelfDestructDurationSheet({super.key, required this.onSelected});

  static Future<void> show(
    BuildContext context, {
    required void Function(int seconds) onSelected,
  }) {
    return AppActionBottomSheet.show<void>(
      context: context,
      title: 'Self-destruct photo',
      actions: _options
          .map(
            (seconds) => AppActionSheetItem(
              iconPath: AppIcons.timer,
              label: '$seconds seconds',
              iconColor: AppColors.accentPurple,
              onTap: () {
                Navigator.pop(context);
                onSelected(seconds);
              },
            ),
          )
          .toList(),
    );
  }

  static const _options = [5, 10, 30, 60];

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetShell(
      title: 'Self-destruct photo',
      actions: _options
          .map(
            (seconds) => AppActionSheetItem(
              iconPath: AppIcons.timer,
              label: '$seconds seconds',
              iconColor: AppColors.accentPurple,
              onTap: () {
                Navigator.pop(context);
                onSelected(seconds);
              },
            ),
          )
          .toList(),
    );
  }
}
