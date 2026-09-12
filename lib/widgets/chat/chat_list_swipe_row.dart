import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/animation_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_icons.dart';
import '../../core/responsive/responsive.dart';

/// Swipe-right reveals Pin + Mute; swipe-left hides (CHAT-MSG-006).
class ChatListSwipeRow extends StatefulWidget {
  final int userId;
  final bool isMuted;
  final bool isPinned;
  final Future<void> Function() onMuteToggle;
  final Future<void> Function() onPinToggle;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDeleted;
  final Widget child;

  const ChatListSwipeRow({
    super.key,
    required this.userId,
    required this.isMuted,
    required this.isPinned,
    required this.onMuteToggle,
    required this.onPinToggle,
    required this.onConfirmDelete,
    required this.onDeleted,
    required this.child,
  });

  static const pinActionKey = ValueKey('chat-swipe-pin');
  static const muteActionKey = ValueKey('chat-swipe-mute');
  static const revealWidth = 152.0;
  static const deleteExtent = 96.0;

  @override
  State<ChatListSwipeRow> createState() => _ChatListSwipeRowState();
}

class _ChatListSwipeRowState extends State<ChatListSwipeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double> _slide = const AlwaysStoppedAnimation<double>(0);
  double _offset = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.transitionPage,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = AppAnimations.chatListSwipeDuration(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final reduce = !AppAnimations.animationsEnabled(context);
    _controller.duration =
        reduce ? Duration.zero : AppAnimations.chatListSwipeDuration(context);
    _slide = Tween<double>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.curveDefault),
    );
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _offset = target);
    });
    setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragging = true;
    final next = (_offset + details.delta.dx).clamp(
      -ChatListSwipeRow.deleteExtent,
      ChatListSwipeRow.revealWidth,
    );
    if (next == _offset) return;
    setState(() => _offset = next);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    _dragging = false;
    if (_offset <= -ChatListSwipeRow.deleteExtent * 0.75) {
      AppHaptics.medium();
      final ok = await widget.onConfirmDelete();
      if (!mounted) return;
      if (ok) {
        widget.onDeleted();
        return;
      }
      _animateTo(0);
      return;
    }
    if (_offset >= ChatListSwipeRow.revealWidth * 0.5) {
      AppHaptics.medium();
      _animateTo(ChatListSwipeRow.revealWidth);
      return;
    }
    _animateTo(0);
  }

  Future<void> _runAction(Future<void> Function() action) async {
    await action();
    if (mounted) _animateTo(0);
  }

  double get _dx {
    if (_dragging || !_controller.isAnimating) return _offset;
    return _slide.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.radiusMD),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    _SwipeActionButton(
                      key: ChatListSwipeRow.pinActionKey,
                      label: widget.isPinned ? 'Unpin' : 'Pin',
                      iconPath: widget.isPinned
                          ? AppIcons.bookmark2
                          : AppIcons.bookmark,
                      background: theme.colorScheme.secondary,
                      foreground: theme.colorScheme.onSecondary,
                      onTap: () => _runAction(widget.onPinToggle),
                    ),
                    _SwipeActionButton(
                      key: ChatListSwipeRow.muteActionKey,
                      label: widget.isMuted ? 'Unmute' : 'Mute',
                      iconPath: widget.isMuted
                          ? AppIcons.bell
                          : AppIcons.bellSlash,
                      background: theme.colorScheme.primary,
                      foreground: theme.colorScheme.onPrimary,
                      onTap: () => _runAction(widget.onMuteToggle),
                    ),
                    const Spacer(),
                    Container(
                      width: ChatListSwipeRow.deleteExtent,
                      color: theme.colorScheme.error,
                      alignment: Alignment.center,
                      child: AppText(
                        'Delete',
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(_dx, 0),
                child: child,
              ),
            ],
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: (details) {
            unawaited(_onDragEnd(details));
          },
          onHorizontalDragCancel: () {
            _dragging = false;
            if (_offset >= ChatListSwipeRow.revealWidth * 0.5) {
              _animateTo(ChatListSwipeRow.revealWidth);
            } else {
              _animateTo(0);
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _SwipeActionButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: ChatListSwipeRow.revealWidth / 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacingXS,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: AppSvgIcon(
                      assetPath: iconPath,
                      size: 20,
                      color: foreground,
                    ),
                  ),
                ),
                AppText(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
