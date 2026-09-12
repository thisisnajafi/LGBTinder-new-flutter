import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing_constants.dart';
import '../../data/models/call_speaking_pulse.dart';

/// Pulse ring around an avatar or PiP while that participant is speaking.
///
/// Scale 1.0→1.12, opacity 0.8→0, 400ms loop. Reduce Motion: static ring.
/// Painter is isolated in a [RepaintBoundary]. Controller is disposed.
class CallSpeakingRing extends StatefulWidget {
  final bool active;
  final Widget child;
  final double? diameter;
  final BorderRadius? borderRadius;

  const CallSpeakingRing({
    super.key,
    required this.active,
    required this.child,
    this.diameter,
    this.borderRadius,
  });

  @override
  State<CallSpeakingRing> createState() => _CallSpeakingRingState();
}

class _CallSpeakingRingState extends State<CallSpeakingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CallSpeakingPulse.duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CallSpeakingRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        widget.active && AppAnimations.animationsEnabled(context);
    if (animate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
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
    final animate = AppAnimations.animationsEnabled(context);
    final circular = widget.diameter != null;
    final extent =
        circular ? widget.diameter! * CallSpeakingPulse.endScale : null;
    final overflow = AppSpacing.spacingSM;

    final ring = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: circular ? Size.square(extent!) : Size.zero,
            painter: _CallSpeakingPainter(
              t: widget.active && animate ? _controller.value : 0,
              color: AppColors.onlineGreen,
              staticRing: widget.active && !animate,
              circular: circular,
              borderRadius: widget.borderRadius,
            ),
            child: circular ? null : const SizedBox.expand(),
          );
        },
      ),
    );

    return Semantics(
      label: widget.active ? 'Speaking' : null,
      child: circular
          ? SizedBox(
              width: extent,
              height: extent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ring,
                  widget.child,
                ],
              ),
            )
          : Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -overflow,
                  top: -overflow,
                  right: -overflow,
                  bottom: -overflow,
                  child: IgnorePointer(child: ring),
                ),
                widget.child,
              ],
            ),
    );
  }
}

class _CallSpeakingPainter extends CustomPainter {
  final double t;
  final Color color;
  final bool staticRing;
  final bool circular;
  final BorderRadius? borderRadius;

  _CallSpeakingPainter({
    required this.t,
    required this.color,
    required this.staticRing,
    required this.circular,
    this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 && !staticRing) return;

    final progress = staticRing ? 0.0 : t;
    final scale = staticRing ? 1.0 : CallSpeakingPulse.scaleFor(progress);
    final opacity =
        staticRing ? CallSpeakingPulse.startOpacity : CallSpeakingPulse.opacityFor(progress);
    if (opacity <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: opacity);

    final center = Offset(size.width / 2, size.height / 2);
    if (circular) {
      final base = size.shortestSide / (2 * CallSpeakingPulse.endScale);
      canvas.drawCircle(center, base * scale, paint);
      return;
    }

    final rect = Rect.fromCenter(
      center: center,
      width: size.width / CallSpeakingPulse.endScale * scale,
      height: size.height / CallSpeakingPulse.endScale * scale,
    );
    final radius = borderRadius ?? BorderRadius.zero;
    canvas.drawRRect(radius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(covariant _CallSpeakingPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color != color ||
        oldDelegate.staticRing != staticRing ||
        oldDelegate.circular != circular ||
        oldDelegate.borderRadius != borderRadius;
  }
}
