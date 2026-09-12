import 'package:flutter/material.dart';

import '../../../../core/constants/animation_constants.dart';
import '../../data/models/call_connect_transition.dart';

/// Drives the one-shot ringing → connected motion (400ms easeOutCubic).
///
/// Reduce Motion and an already-connected first frame jump to the
/// connected layout. The controller is never reversed (hang-up is CALL-UI-003).
class CallConnectHost extends StatefulWidget {
  final bool connected;
  final Widget child;

  const CallConnectHost({
    super.key,
    required this.connected,
    required this.child,
  });

  @override
  State<CallConnectHost> createState() => _CallConnectHostState();
}

class _CallConnectHostState extends State<CallConnectHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  var _played = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.callConnect,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveDefault,
    );
    if (widget.connected) {
      _controller.value = 1;
      _played = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = !AppAnimations.animationsEnabled(context);
    _controller.duration = CallConnectTransition.duration(
      reduceMotion: reduce,
    );
    if (widget.connected && reduce && _controller.value < 1) {
      _controller.value = 1;
      _played = true;
    }
  }

  @override
  void didUpdateWidget(CallConnectHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connected && !oldWidget.connected && !_played) {
      _played = true;
      if (AppAnimations.animationsEnabled(context)) {
        _controller.forward();
      } else {
        _controller.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallConnectScope(
      progress: _curved,
      child: widget.child,
    );
  }
}

class CallConnectScope extends InheritedWidget {
  final Animation<double> progress;

  const CallConnectScope({
    super.key,
    required this.progress,
    required super.child,
  });

  static CallConnectScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CallConnectScope>();
  }

  static Animation<double> progressOf(BuildContext context) {
    return maybeOf(context)?.progress ?? const AlwaysStoppedAnimation(1);
  }

  @override
  bool updateShouldNotify(CallConnectScope oldWidget) {
    return oldWidget.progress != progress;
  }
}

/// Collapses the ringing pulse (opacity + scale). Hidden at t = 1.
class CallConnectPulse extends StatelessWidget {
  final Widget child;

  const CallConnectPulse({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final progress = CallConnectScope.progressOf(context);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final t = progress.value;
        if (t >= 1) return const SizedBox.shrink();
        return Opacity(
          key: const ValueKey('call-connect-pulse'),
          opacity: CallConnectTransition.pulseOpacity(t),
          child: Transform.scale(
            scale: CallConnectTransition.pulseScale(t),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Fades and scales in remote video / the connected avatar.
class CallConnectStage extends StatelessWidget {
  final Widget child;

  const CallConnectStage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final progress = CallConnectScope.progressOf(context);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final t = progress.value;
        return Opacity(
          key: const ValueKey('call-connect-stage'),
          opacity: CallConnectTransition.stageOpacity(t),
          child: Transform.scale(
            scale: CallConnectTransition.stageScale(t),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Timer (or any connected status) fades in from below.
class CallConnectTimer extends StatelessWidget {
  final Widget child;

  const CallConnectTimer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final progress = CallConnectScope.progressOf(context);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final t = progress.value;
        return Opacity(
          key: const ValueKey('call-connect-timer'),
          opacity: CallConnectTransition.timerOpacity(t),
          child: Transform.translate(
            offset: Offset(0, CallConnectTransition.timerSlideY(t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Ringing label fades out as the timer appears.
class CallConnectRingingLabel extends StatelessWidget {
  final Widget child;

  const CallConnectRingingLabel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final progress = CallConnectScope.progressOf(context);
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final t = progress.value;
        if (t >= 1) return const SizedBox.shrink();
        return Opacity(
          key: const ValueKey('call-connect-ringing'),
          opacity: CallConnectTransition.pulseOpacity(t),
          child: child,
        );
      },
      child: child,
    );
  }
}
