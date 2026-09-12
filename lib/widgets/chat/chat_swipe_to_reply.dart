import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_icons.dart';
import '../../features/chat/utils/chat_swipe_to_reply.dart';

/// Swipe a bubble toward the thread center to reply (CHAT-ANIM-010).
///
/// Sent (right-aligned) swipes left; received swipes right. Crossing 60px
/// haptics; releasing past the threshold springs back and calls [onReply].
/// Sub-threshold release snaps back with no reply. Reduce Motion skips the
/// spring. Call rows are not wrapped by this widget.
class ChatSwipeToReply extends StatefulWidget {
  final bool isSent;
  final VoidCallback onReply;
  final Widget child;

  const ChatSwipeToReply({
    super.key,
    required this.isSent,
    required this.onReply,
    required this.child,
  });

  @override
  State<ChatSwipeToReply> createState() => _ChatSwipeToReplyState();
}

class _ChatSwipeToReplyState extends State<ChatSwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  final ValueNotifier<double> _dx = ValueNotifier<double>(0);
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController.unbounded(vsync: this)
      ..addListener(() => _dx.value = _spring.value);
  }

  @override
  void didUpdateWidget(covariant ChatSwipeToReply oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSent != widget.isSent) {
      _reset();
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    _dx.dispose();
    super.dispose();
  }

  void _reset() {
    _spring.stop();
    _spring.value = 0;
    _dx.value = 0;
    _armed = false;
  }

  void _onDragStart(DragStartDetails _) {
    _spring.stop();
    _armed = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dx.value = ChatSwipeToReplyPhysics.clampDx(
      _dx.value + details.delta.dx,
      isSent: widget.isSent,
    );
    final crossed = ChatSwipeToReplyPhysics.crossed(_dx.value);
    if (crossed && !_armed) {
      AppHaptics.medium();
    }
    _armed = crossed;
  }

  void _onDragEnd(DragEndDetails _) {
    final dx = _dx.value;
    final reply = ChatSwipeToReplyPhysics.shouldReply(
      dx,
      isSent: widget.isSent,
    );
    if (reply && !_armed) {
      AppHaptics.medium();
    }
    _armed = false;
    _snapBack(from: dx);
    if (reply) widget.onReply();
  }

  void _onDragCancel() {
    _armed = false;
    _snapBack(from: _dx.value);
  }

  void _snapBack({required double from}) {
    if (from == 0) return;
    if (!AppAnimations.animationsEnabled(context)) {
      _spring.value = 0;
      _dx.value = 0;
      return;
    }
    _spring.value = from;
    _spring.animateTo(
      0,
      duration: AppAnimations.chatSwipeReplySpring,
      curve: AppAnimations.chatSwipeReplySpringCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      behavior: HitTestBehavior.translucent,
      child: ValueListenableBuilder<double>(
        valueListenable: _dx,
        child: widget.child,
        builder: (context, dx, child) {
          final progress = ChatSwipeToReplyPhysics.progress(dx);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: widget.isSent
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(
                          ChatSwipeToReplyPhysics.iconFollowDx(dx),
                          0,
                        ),
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * progress,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacingLG,
                            ),
                            child: Semantics(
                              label: 'Reply',
                              child: AppSvgIcon(
                                assetPath: AppIcons.reply,
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }
}
