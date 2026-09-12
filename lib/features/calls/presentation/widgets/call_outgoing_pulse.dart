import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/border_radius_constants.dart';
import '../../../../core/widgets/profile_image_widget.dart';
import '../../data/models/call_outgoing_pulse.dart';
import '../../providers/agora_rtc_session_provider.dart';
import '../../providers/live_call_ui_provider.dart';
import 'call_speaking_ring.dart';

/// Concentric pulse rings around the callee avatar while ringing / connecting.
class CallOutgoingPulseAvatar extends ConsumerWidget {
  final bool active;
  final int userId;
  final String? imageUrl;
  final double avatarSize;

  const CallOutgoingPulseAvatar({
    super.key,
    required this.active,
    required this.userId,
    this.imageUrl,
    this.avatarSize = 120,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speaking = ref.watch(callStatusProvider) &&
        ref.watch(remoteSpeakingProvider);
    return CallOutgoingPulseRings(
      active: active,
      avatarSize: avatarSize,
      child: CallSpeakingRing(
        active: speaking,
        diameter: avatarSize,
        child: ClipOval(
          child: SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: ProfileImageWidget(
              imageUrl: imageUrl,
              userId: userId,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(AppRadius.radiusRound),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints three staggered rings around [child]. Controller is disposed here.
class CallOutgoingPulseRings extends StatefulWidget {
  final bool active;
  final double avatarSize;
  final Widget child;

  const CallOutgoingPulseRings({
    super.key,
    required this.active,
    required this.avatarSize,
    required this.child,
  });

  @override
  State<CallOutgoingPulseRings> createState() => _CallOutgoingPulseRingsState();
}

class _CallOutgoingPulseRingsState extends State<CallOutgoingPulseRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CallOutgoingPulse.controllerDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CallOutgoingPulseRings oldWidget) {
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
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = AppColors.primaryLight;
    final animate = AppAnimations.animationsEnabled(context);
    final extent = widget.avatarSize * CallOutgoingPulse.endScale;

    return Semantics(
      label: widget.active ? 'Calling' : null,
      child: SizedBox(
        width: extent,
        height: extent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.square(extent),
                    painter: _CallOutgoingPulsePainter(
                      t: widget.active && animate ? _controller.value : 0,
                      color: ringColor,
                      avatarSize: widget.avatarSize,
                      staticRing: widget.active && !animate,
                    ),
                  );
                },
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _CallOutgoingPulsePainter extends CustomPainter {
  final double t;
  final Color color;
  final double avatarSize;
  final bool staticRing;

  _CallOutgoingPulsePainter({
    required this.t,
    required this.color,
    required this.avatarSize,
    required this.staticRing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = avatarSize / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (staticRing) {
      paint.color = color.withValues(alpha: CallOutgoingPulse.peakOpacity);
      canvas.drawCircle(center, baseRadius, paint);
      return;
    }

    for (var i = 0; i < CallOutgoingPulse.ringCount; i++) {
      final progress = CallOutgoingPulse.ringProgress(i, t);
      if (progress == null) continue;
      paint.color = color.withValues(
        alpha: CallOutgoingPulse.opacityFor(progress),
      );
      canvas.drawCircle(
        center,
        baseRadius * CallOutgoingPulse.scaleFor(progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CallOutgoingPulsePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color != color ||
        oldDelegate.avatarSize != avatarSize ||
        oldDelegate.staticRing != staticRing;
  }
}
