import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/notification_provider.dart';

/// Notification badge widget
/// Shows notification count with animated badge
class NotificationBadge extends ConsumerStatefulWidget {
  final Widget child;
  final double badgeSize;
  final Color badgeColor;
  final Color textColor;
  final Offset position;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeSize = 18,
    this.badgeColor = AppColors.feedbackError,
    this.textColor = Colors.white,
    this.position = const Offset(8, -8),
  }) : super(key: key);

  @override
  ConsumerState<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends ConsumerState<NotificationBadge>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (notificationState.unreadCount > 0) ...[
          Positioned(
            top: widget.position.dy,
            right: widget.position.dx,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: widget.badgeSize,
                  minHeight: widget.badgeSize,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.badgeColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getBadgeText(notificationState.unreadCount),
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: widget.badgeSize * 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getBadgeText(int count) {
    if (count > 99) {
      return '99+';
    }
    return count.toString();
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate when unread count changes
    final notificationState = ref.read(notificationProvider);
    if (notificationState.unreadCount > 0) {
      _animationController.reset();
      _animationController.forward();
    }
  }
}

/// Notification dot widget (for simple indicators)
class NotificationDot extends ConsumerWidget {
  final double size;
  final Color color;

  const NotificationDot({
    Key? key,
    this.size = 8,
    this.color = AppColors.feedbackError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return notificationState.unreadCount > 0
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}

/// Animated notification counter
class AnimatedNotificationCounter extends ConsumerStatefulWidget {
  final TextStyle? style;
  final Duration duration;

  const AnimatedNotificationCounter({
    Key? key,
    this.style,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  ConsumerState<AnimatedNotificationCounter> createState() => _AnimatedNotificationCounterState();
}

class _AnimatedNotificationCounterState extends ConsumerState<AnimatedNotificationCounter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final count = notificationState.unreadCount;

    // Trigger animation when count changes
    if (count != _previousCount && count > 0) {
      _controller.reset();
      _controller.forward();
      _previousCount = count;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Text(
            count.toString(),
            style: widget.style ?? Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.feedbackError,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
