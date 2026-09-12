import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';

/// Owns video-call HUD visibility (header + controls). Voice passes
/// [autoHide] false so chrome stays on.
class CallHudHost extends StatefulWidget {
  final bool autoHide;
  final Widget child;

  const CallHudHost({
    super.key,
    required this.autoHide,
    required this.child,
  });

  @override
  State<CallHudHost> createState() => _CallHudHostState();
}

class _CallHudHostState extends State<CallHudHost> {
  bool _visible = true;
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    if (widget.autoHide) {
      _armIdle();
    }
  }

  @override
  void didUpdateWidget(CallHudHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.autoHide) {
      _idle?.cancel();
      if (!_visible) {
        setState(() => _visible = true);
      }
      return;
    }
    if (!oldWidget.autoHide && widget.autoHide) {
      _reveal();
    }
  }

  void _reveal() {
    _idle?.cancel();
    if (!_visible) {
      setState(() => _visible = true);
    }
    if (widget.autoHide) {
      _armIdle();
    }
  }

  void _armIdle() {
    _idle?.cancel();
    _idle = Timer(AppAnimations.callHudIdle, () {
      if (!mounted || !widget.autoHide) return;
      setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallHudController(
      visible: _visible,
      reveal: _reveal,
      child: widget.child,
    );
  }
}

class CallHudController extends InheritedWidget {
  final bool visible;
  final VoidCallback reveal;

  const CallHudController({
    super.key,
    required this.visible,
    required this.reveal,
    required super.child,
  });

  static CallHudController of(BuildContext context) {
    final hud = context.dependOnInheritedWidgetOfExactType<CallHudController>();
    assert(hud != null, 'CallHudController missing');
    return hud!;
  }

  /// Does not subscribe — safe to call from Agora video tiles.
  static CallHudController? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<CallHudController>();
  }

  @override
  bool updateShouldNotify(CallHudController oldWidget) =>
      visible != oldWidget.visible;
}

/// Fades header/controls with the HUD. Hidden chrome does not absorb taps.
class CallHudFade extends StatelessWidget {
  final Widget child;

  const CallHudFade({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final hud = CallHudController.of(context);
    final animate = AppAnimations.animationsEnabled(context);
    return IgnorePointer(
      ignoring: !hud.visible,
      child: Listener(
        onPointerDown: (_) => hud.reveal(),
        child: AnimatedOpacity(
          opacity: hud.visible ? 1 : 0,
          duration: animate ? AppAnimations.callHudFade : Duration.zero,
          curve: AppAnimations.curveDefault,
          child: child,
        ),
      ),
    );
  }
}
