import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/providers/chat_image_upload_progress_provider.dart';
import '../../features/chat/utils/chat_send_retry.dart';

/// Circular 0–100% upload arc over an optimistic image (CHAT-IMG-001).
class ChatImageSendOverlay extends ConsumerStatefulWidget {
  final String? clientId;
  final bool isFailed;
  final bool isSending;
  final VoidCallback? onRetry;

  const ChatImageSendOverlay({
    super.key,
    this.clientId,
    this.isFailed = false,
    this.isSending = false,
    this.onRetry,
  });

  @override
  ConsumerState<ChatImageSendOverlay> createState() =>
      _ChatImageSendOverlayState();
}

class _ChatImageSendOverlayState extends ConsumerState<ChatImageSendOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  bool _fadingOut = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      value: 1,
      duration: AppAnimations.feedbackShort,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fadeOutAndClear(String clientId) async {
    if (_fadingOut) return;
    _fadingOut = true;
    final animate =
        mounted && AppAnimations.animationsEnabled(context);
    _fadeController.duration =
        animate ? AppAnimations.feedbackShort : Duration.zero;
    await _fadeController.reverse();
    if (!mounted) return;
    ref.read(chatImageUploadProgressProvider.notifier).clear(clientId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFailed) {
      return SizedBox.expand(
        child: _FailedOverlay(onRetry: widget.onRetry),
      );
    }

    final clientId = widget.clientId;
    final progress = clientId == null
        ? null
        : ref.watch(
            chatImageUploadProgressProvider.select((map) => map[clientId]),
          );

    if (clientId != null) {
      ref.listen<double?>(
        chatImageUploadProgressProvider.select((map) => map[clientId]),
        (previous, next) {
          if (next != null && next >= 1.0) {
            unawaited(_fadeOutAndClear(clientId));
          }
        },
      );
    }

    if (!widget.isSending && progress == null) {
      return const SizedBox.shrink();
    }

    final fraction = progress ?? 0.0;
    final percent = (fraction * 100).round().clamp(0, 100);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox.expand(
      child: FadeTransition(
        opacity: _fadeController,
        child: ColoredBox(
          color: AppColors.backgroundDark.withValues(alpha: 0.45),
          child: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _UploadArcPainter(
                    progress: fraction,
                    color: AppColors.primaryLight,
                    trackColor:
                        AppColors.textPrimaryDark.withValues(alpha: 0.28),
                  ),
                  child: Center(
                    child: Text(
                      '$percent%',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FailedOverlay extends StatelessWidget {
  final VoidCallback? onRetry;

  const _FailedOverlay({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onRetry != null,
      container: true,
      label: onRetry == null
          ? ChatSendRetry.lockedLabel
          : 'Retry sending photo',
      child: GestureDetector(
        onTap: onRetry,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: AppColors.backgroundDark.withValues(alpha: 0.5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: AppSvgIcon(
                assetPath: AppIcons.close,
                size: 36,
                color: AppColors.feedbackError,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _UploadArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..color = trackColor
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
  bool shouldRepaint(covariant _UploadArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
