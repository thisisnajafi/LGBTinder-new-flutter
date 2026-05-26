import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/animation_constants.dart';
import '../theme/app_colors.dart';

/// Thin indeterminate arc loader for splash / brand moments.
class SplashArcLoader extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  const SplashArcLoader({
    super.key,
    this.size = 40,
    this.strokeWidth = 3,
    this.color = AppColors.accentRose,
  });

  @override
  State<SplashArcLoader> createState() => _SplashArcLoaderState();
}

class _SplashArcLoaderState extends State<SplashArcLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppAnimations.animationsEnabled(context)) {
      _controller.stop();
      _controller.value = 0.25;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = !AppAnimations.animationsEnabled(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: disableAnimations
          ? CustomPaint(
              painter: _ArcLoaderPainter(
                progress: 0.25,
                strokeWidth: widget.strokeWidth,
                color: widget.color,
              ),
            )
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ArcLoaderPainter(
                    progress: _controller.value,
                    strokeWidth: widget.strokeWidth,
                    color: widget.color,
                  ),
                );
              },
            ),
    );
  }
}

class _ArcLoaderPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _ArcLoaderPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const sweep = math.pi * 1.35;
    final start = progress * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
