import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../features/chat/utils/voice_waveform_layout.dart';

/// Voice waveform as a single [CustomPainter] (CHAT-ANIM-011).
///
/// Playback progress recolors bars (played = [color], remaining = muted).
/// Idle motion runs only while [active] and Reduce Motion is off.
class VoiceWaveformBars extends StatefulWidget {
  final bool active;
  final Color color;
  final double height;
  final int barCount;
  final double progress;

  const VoiceWaveformBars({
    super.key,
    required this.active,
    required this.color,
    this.height = 28,
    this.barCount = AppAnimations.chatVoiceWaveformBars,
    this.progress = 0,
  });

  @override
  State<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends State<VoiceWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.chatVoiceWaveformIdle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant VoiceWaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final motion =
        widget.active && AppAnimations.animationsEnabled(context);
    if (motion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate =
        widget.active && AppAnimations.animationsEnabled(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 160.0;
        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(maxWidth, widget.height),
                painter: VoiceWaveformPainter(
                  barCount: widget.barCount,
                  progress: widget.progress,
                  t: animate ? _controller.value : 0,
                  active: widget.active,
                  animate: animate,
                  color: widget.color,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Paints [barCount] rounded bars; [shouldRepaint] is the only invalidate path.
class VoiceWaveformPainter extends CustomPainter {
  final int barCount;
  final double progress;
  final double t;
  final bool active;
  final bool animate;
  final Color color;

  const VoiceWaveformPainter({
    required this.barCount,
    required this.progress,
    required this.t,
    required this.active,
    required this.animate,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (barCount <= 0 || size.width <= 0 || size.height <= 0) return;
    final barW = VoiceWaveformLayout.barWidth(size.width, barCount);
    final muted = color.withValues(
      alpha: active
          ? VoiceWaveformLayout.mutedAlphaActive
          : VoiceWaveformLayout.mutedAlphaIdle,
    );
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < barCount; i++) {
      final played = VoiceWaveformLayout.playedFraction(
        index: i,
        barCount: barCount,
        progress: progress,
      );
      paint.color = Color.lerp(muted, color, played)!;
      final factor = VoiceWaveformLayout.heightFactor(
        index: i,
        barCount: barCount,
        t: t,
        active: active,
        animate: animate,
      );
      final h = math.max(2.0, size.height * factor);
      final x = i * (barW + VoiceWaveformLayout.gap);
      final y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          Radius.circular(barW),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant VoiceWaveformPainter oldDelegate) {
    return oldDelegate.barCount != barCount ||
        oldDelegate.progress != progress ||
        oldDelegate.t != t ||
        oldDelegate.active != active ||
        oldDelegate.animate != animate ||
        oldDelegate.color != color;
  }
}

/// Pulsing red dot shown while recording voice.
class PulsingRecordDot extends StatefulWidget {
  final Color color;

  const PulsingRecordDot({super.key, required this.color});

  @override
  State<PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.chatVoiceWaveformIdle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.animationsEnabled(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppAnimations.animationsEnabled(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = motion ? 0.85 + (_controller.value * 0.3) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.45),
                  blurRadius: 6 + (_controller.value * 4),
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
