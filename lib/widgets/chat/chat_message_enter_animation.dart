import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';

/// One-shot slide + fade (+ outgoing scale) for a newly inserted chat bubble.
///
/// Outgoing (CHAT-THREAD-001): [Offset] (0.15, 0.3) → 0, fade 0 → 1,
/// scale 0.85 → 1, 220ms [Curves.easeOutCubic].
/// Incoming (CHAT-THREAD-002): [Offset] (-0.15, 0.1) → 0, fade 0 → 1,
/// 260ms [Curves.easeOutBack]. History and pagination rows do not play this
/// (`ChatMessageEnterGate`). Reduce Motion uses [Duration.zero].
class ChatMessageEnterAnimation extends StatefulWidget {
  final bool play;
  final bool isSent;
  final Widget child;

  const ChatMessageEnterAnimation({
    super.key,
    required this.play,
    required this.isSent,
    required this.child,
  });

  @override
  State<ChatMessageEnterAnimation> createState() =>
      _ChatMessageEnterAnimationState();
}

class _ChatMessageEnterAnimationState extends State<ChatMessageEnterAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.isSent
          ? AppAnimations.chatMessageSend
          : AppAnimations.chatMessageReceive,
    );
    final slideCurve = CurvedAnimation(
      parent: _controller,
      curve: widget.isSent
          ? AppAnimations.curveDefault
          : AppAnimations.chatMessageReceiveCurve,
    );
    // easeOutBack overshoots past 1.0 — never drive Opacity with it.
    final fadeCurve = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveDefault,
    );
    final begin = widget.isSent
        ? AppAnimations.chatMessageSendSlide
        : AppAnimations.chatMessageReceiveSlide;
    _slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(slideCurve);
    _fade = Tween<double>(begin: 0, end: 1).animate(fadeCurve);
    _scale = Tween<double>(
      begin: widget.isSent ? AppAnimations.chatMessageSendScaleBegin : 1,
      end: 1,
    ).animate(fadeCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final skip = !widget.play || !AppAnimations.animationsEnabled(context);
    if (skip) {
      _controller.duration = Duration.zero;
      _controller.value = 1;
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (widget.isSent) {
      child = ScaleTransition(
        key: const ValueKey('chat-message-enter-scale'),
        scale: _scale,
        alignment: Alignment.centerRight,
        child: child,
      );
    }
    return FadeTransition(
      key: const ValueKey('chat-message-enter-fade'),
      opacity: _fade,
      child: SlideTransition(
        key: const ValueKey('chat-message-enter-slide'),
        position: _slide,
        child: child,
      ),
    );
  }
}
