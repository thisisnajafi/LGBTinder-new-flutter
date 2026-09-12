import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/animation_constants.dart';
import '../../features/chat/providers/chat_thread_providers.dart';

/// Springs the thread slightly past the latest edge when a new row lands
/// while the user is already at the bottom (CHAT-ANIM-013).
class ChatArrivalBounceLayer extends ConsumerStatefulWidget {
  final int peerUserId;
  final Widget child;

  const ChatArrivalBounceLayer({
    super.key,
    required this.peerUserId,
    required this.child,
  });

  @override
  ConsumerState<ChatArrivalBounceLayer> createState() =>
      _ChatArrivalBounceLayerState();
}

class _ChatArrivalBounceLayerState
    extends ConsumerState<ChatArrivalBounceLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dy;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.chatArrivalBounce,
    );
    _dy = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: AppAnimations.chatArrivalBounceOvershoot,
        ).chain(CurveTween(curve: AppAnimations.curveDefault)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppAnimations.chatArrivalBounceOvershoot,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(chatArrivalBounceProvider(widget.peerUserId),
        (previous, next) {
      if (!AppAnimations.animationsEnabled(context)) return;
      if (next > (previous ?? 0)) {
        _controller.forward(from: 0);
      }
    });
    return AnimatedBuilder(
      animation: _dy,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          key: const ValueKey('chat-arrival-bounce'),
          offset: Offset(0, _dy.value),
          child: child,
        );
      },
    );
  }
}
