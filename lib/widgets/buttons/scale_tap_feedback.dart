// Wraps a child with scale-down-on-press feedback using AppAnimations.
// Use for icon buttons, nav items, and any tappable that should feel consistent.

import 'package:flutter/material.dart';
import '../../core/constants/animation_constants.dart';

/// Wraps [child] with press scale feedback (1 → [AppAnimations.buttonPressScale]).
/// Respects [MediaQuery.disableAnimations]. Call [onTap] on tap up.
class ScaleTapFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ScaleTapFeedback({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  State<ScaleTapFeedback> createState() => _ScaleTapFeedbackState();
}

class _ScaleTapFeedbackState extends State<ScaleTapFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.tapDuration,
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: AppAnimations.buttonPressScale)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveDefault,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (AppAnimations.animationsEnabled(context)) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
