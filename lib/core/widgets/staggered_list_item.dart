// Staggered list item — fade-in + short slide on first load.
// Use for chat list, notifications, settings rows. Only animates when [animateAppear] is true.

import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/animation_constants.dart';

/// Wraps [child] with a staggered appear: opacity 0→1 and slide from (0, 25) to (0, 0).
/// [index] is used for delay: start after index * [AppAnimations.listItemStagger].
/// Set [animateAppear] to false to show [child] immediately (e.g. after initial load).
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final bool animateAppear;

  const StaggeredListItem({
    Key? key,
    required this.index,
    required this.child,
    this.animateAppear = true,
  }) : super(key: key);

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.listItemAppear,
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveDefault),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveDefault),
    );

    if (!widget.animateAppear) return;
    // Schedule timer after first frame so context is valid and we don't block initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final duration = AppAnimations.animationsEnabled(context)
          ? Duration(
              milliseconds:
                  widget.index * AppAnimations.listItemStagger.inMilliseconds,
            )
          : Duration.zero;
      _delayTimer = Timer(duration, () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animateAppear) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
