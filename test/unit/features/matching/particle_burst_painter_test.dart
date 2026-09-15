import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/matching/widgets/particle_burst_painter.dart';

void main() {
  test('computeBurst caps particles at maxParticleCount', () {
    final particles = ParticleBurstPainter.computeBurst(
      center: Offset.zero,
      t: 0.5,
      palette: const [Color(0xFF000000)],
      count: 50,
    );
    expect(particles.length, ParticleBurstPainter.maxParticleCount);
    expect(particles.length, lessThanOrEqualTo(14));
  });

  test('computeBurst returns empty when count is zero', () {
    final particles = ParticleBurstPainter.computeBurst(
      center: Offset.zero,
      t: 0.5,
      palette: const [Color(0xFF000000)],
      count: 0,
    );
    expect(particles, isEmpty);
  });
}
