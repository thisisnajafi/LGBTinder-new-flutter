import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/constants/animation_constants.dart';

/// Pads the chat column by [MediaQuery.viewInsets] (CHAT-THREAD-010).
/// Pair with `resizeToAvoidBottomInset: false` so Scaffold does not pad twice.
class ChatKeyboardInsetPad extends StatefulWidget {
  final Widget child;
  final ValueChanged<double>? onBottomInsetChanged;
  final VoidCallback? onInsetAnimationEnd;

  /// Fired after each pad-size change (keyboard animation frames).
  final VoidCallback? onInsetTick;

  const ChatKeyboardInsetPad({
    super.key,
    required this.child,
    this.onBottomInsetChanged,
    this.onInsetAnimationEnd,
    this.onInsetTick,
  });

  @override
  State<ChatKeyboardInsetPad> createState() => _ChatKeyboardInsetPadState();
}

class _ChatKeyboardInsetPadState extends State<ChatKeyboardInsetPad> {
  double _lastReported = -1;
  BoxConstraints? _lastTickConstraints;

  void _reportInset(double bottom) {
    if (bottom == _lastReported) return;
    _lastReported = bottom;
    widget.onBottomInsetChanged?.call(bottom);
  }

  void _scheduleTick() {
    if (widget.onInsetTick == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onInsetTick?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reportInset(MediaQuery.viewInsetsOf(context).bottom);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final reduceMotion = !AppAnimations.animationsEnabled(context);
    return AnimatedPadding(
      key: const ValueKey('chat-keyboard-inset-pad'),
      duration: reduceMotion ? Duration.zero : AppAnimations.transitionModal,
      curve: AppAnimations.curveDefault,
      padding: EdgeInsets.only(bottom: bottom),
      onEnd: widget.onInsetAnimationEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_lastTickConstraints != constraints) {
            _lastTickConstraints = constraints;
            _scheduleTick();
          }
          return widget.child;
        },
      ),
    );
  }
}
