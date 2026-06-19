import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/animation_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Subtle floating particles behind the discover screen.
class DiscoverAmbientBackground extends StatefulWidget {
  const DiscoverAmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<DiscoverAmbientBackground> createState() =>
      _DiscoverAmbientBackgroundState();
}

class _DiscoverAmbientBackgroundState extends State<DiscoverAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppAnimations.animationsEnabled(context)) {
      _controller.stop();
      _controller.value = 0;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _DiscoverParticlesPainter(
                drift: _controller.value,
                isDark: isDark,
              ),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _DiscoverParticlesPainter extends CustomPainter {
  _DiscoverParticlesPainter({
    required this.drift,
    required this.isDark,
  });

  final double drift;
  final bool isDark;

  static final _palette = [
    AppColors.accentPink,
    AppColors.lgbtGradient[5],
    AppColors.accentPurple,
    AppColors.lgbtGradient[4],
    AppColors.lgbtGradient[1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final baseAlpha = isDark ? 0.14 : 0.10;
    final count = 28;

    for (var i = 0; i < count; i++) {
      final seed = i * 1.618;
      final xNorm = (math.sin(seed) * 0.5 + 0.5);
      final yNorm = (math.cos(seed * 1.3) * 0.5 + 0.5);
      final waveX = math.sin((drift * math.pi * 2) + seed) * 12;
      final waveY = math.cos((drift * math.pi * 2) + seed * 0.7) * 16;
      final x = xNorm * size.width + waveX;
      final y = yNorm * size.height + waveY;
      final radius = 1.5 + (i % 4) * 0.75;
      final opacity =
          (baseAlpha + (math.sin(drift * math.pi * 2 + seed) * 0.04))
              .clamp(0.06, 0.22);

      final paint = Paint()
        ..color = _palette[i % _palette.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Soft gradient orbs for depth.
    _drawOrb(
      canvas,
      size,
      center: Offset(size.width * 0.85, size.height * 0.12),
      radius: size.width * 0.35,
      color: AppColors.accentPurple.withValues(alpha: isDark ? 0.07 : 0.05),
      driftOffset: Offset(math.sin(drift * math.pi * 2) * 18, 0),
    );
    _drawOrb(
      canvas,
      size,
      center: Offset(size.width * 0.1, size.height * 0.72),
      radius: size.width * 0.28,
      color: AppColors.accentPink.withValues(alpha: isDark ? 0.06 : 0.04),
      driftOffset: Offset(0, math.cos(drift * math.pi * 2) * 14),
    );
  }

  void _drawOrb(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required Offset driftOffset,
  }) {
    final shifted = center + driftOffset;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: shifted, radius: radius));
    canvas.drawCircle(shifted, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _DiscoverParticlesPainter oldDelegate) {
    return oldDelegate.drift != drift || oldDelegate.isDark != isDark;
  }
}
