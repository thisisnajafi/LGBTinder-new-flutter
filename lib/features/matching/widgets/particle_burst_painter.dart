import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual state for a single celebration particle.
class ParticleState {
  final Offset position;
  final double opacity;
  final Color color;
  final double radius;

  const ParticleState({
    required this.position,
    required this.opacity,
    required this.color,
    required this.radius,
  });
}

/// Radiating particle burst drawn with [Canvas.drawCircle].
class ParticleBurstPainter extends CustomPainter {
  ParticleBurstPainter({required this.particles});

  final List<ParticleState> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (particle.opacity <= 0) continue;
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleBurstPainter oldDelegate) {
    if (oldDelegate.particles.length != particles.length) return true;
    for (var i = 0; i < particles.length; i++) {
      final a = oldDelegate.particles[i];
      final b = particles[i];
      if (a.position != b.position ||
          a.opacity != b.opacity ||
          a.color != b.color ||
          a.radius != b.radius) {
        return true;
      }
    }
    return false;
  }

  /// Build particle states for a circular burst from [center] at progress [t] (0–1).
  static List<ParticleState> computeBurst({
    required Offset center,
    required double t,
    required List<Color> palette,
    int count = 14,
    double maxDistance = 72,
  }) {
    final particles = <ParticleState>[];
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final distance = maxDistance * Curves.easeOut.transform(t);
      final position = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      final color = palette[i % palette.length];
      final radius = 4.0 + (i % 3);
      particles.add(
        ParticleState(
          position: position,
          opacity: opacity,
          color: color,
          radius: radius,
        ),
      );
    }
    return particles;
  }
}
