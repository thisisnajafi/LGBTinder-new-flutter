import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Overlay burst from the chat send button (CHAT-ANIM-004).
class ChatSendCelebrationBurst extends StatefulWidget {
  final Offset globalCenter;
  final List<Color> colors;
  final VoidCallback onDone;

  const ChatSendCelebrationBurst({
    super.key,
    required this.globalCenter,
    required this.onDone,
    this.colors = AppColors.lgbtGradient,
  });

  @override
  State<ChatSendCelebrationBurst> createState() =>
      _ChatSendCelebrationBurstState();
}

class _ChatSendCelebrationBurstState extends State<ChatSendCelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.chatEmojiCelebration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onDone();
      return;
    }
    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final overlay = Overlay.maybeOf(context);
            final overlayBox =
                overlay?.context.findRenderObject() as RenderBox?;
            final local = overlayBox?.globalToLocal(widget.globalCenter) ??
                widget.globalCenter;
            final t = Curves.easeOut.transform(_controller.value);
            return RepaintBoundary(
              child: CustomPaint(
                painter: ChatSendCelebrationPainter(
                  particles: ChatSendCelebrationPainter.compute(
                    center: local,
                    t: t,
                    palette: widget.colors,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ChatSendCelebrationPainter extends CustomPainter {
  ChatSendCelebrationPainter({required this.particles});

  final List<ChatSendCelebrationParticle> particles;

  static List<ChatSendCelebrationParticle> compute({
    required Offset center,
    required double t,
    required List<Color> palette,
    int count = AppAnimations.chatEmojiCelebrationParticles,
    double travel = AppAnimations.chatEmojiCelebrationTravel,
  }) {
    final particles = <ChatSendCelebrationParticle>[];
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi - math.pi / 2;
      final distance = travel * t;
      particles.add(
        ChatSendCelebrationParticle(
          position: center +
              Offset(math.cos(angle), math.sin(angle)) * distance,
          opacity: (1.0 - t).clamp(0.0, 1.0),
          color: palette[i % palette.length],
          radius: 5 + (i % 2).toDouble(),
        ),
      );
    }
    return particles;
  }

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
  bool shouldRepaint(covariant ChatSendCelebrationPainter oldDelegate) {
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
}

class ChatSendCelebrationParticle {
  final Offset position;
  final double opacity;
  final Color color;
  final double radius;

  const ChatSendCelebrationParticle({
    required this.position,
    required this.opacity,
    required this.color,
    required this.radius,
  });
}
