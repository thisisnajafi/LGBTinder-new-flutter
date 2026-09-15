// Widget: NotificationBadge
// Notification count badge — scale pulse only when count changes
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/constants/animation_constants.dart';

/// Notification count badge widget
/// Displays a red circular badge with notification count; brief scale pulse when count changes
class NotificationBadge extends StatefulWidget {
  final int count;
  final double? size;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size,
    this.showZero = false,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.snackbarTransition,
      vsync: this,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.curveDefault,
    ));
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count == widget.count) return;
    if (widget.count <= 0 && !widget.showZero) return;
    if (!AppAnimations.animationsEnabled(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeSize = widget.size ?? 20.0;
    final count = widget.count;

    if (count <= 0 && !widget.showZero) {
      return const SizedBox.shrink();
    }

    final displayCount = count > 99 ? '99+' : count.toString();
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: displayCount.length > 1 ? 4 : 0,
      ),
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      decoration: BoxDecoration(
        color: AppColors.notificationRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.notificationRed.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            displayCount,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ),
    );

    if (!AppAnimations.animationsEnabled(context)) {
      return content;
    }
    return ScaleTransition(
      scale: _scale,
      child: content,
    );
  }
}
