// Widget: NotificationBadge
// Notification count badge — optional scale pulse when count changes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';
import '../../core/constants/animation_constants.dart';

/// Notification count badge widget
/// Displays a red circular badge with notification count; brief scale pulse when count changes
class NotificationBadge extends ConsumerStatefulWidget {
  final int count;
  final double? size;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    required this.count,
    this.size,
    this.showZero = false,
  }) : super(key: key);

  @override
  ConsumerState<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends ConsumerState<NotificationBadge>
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
    // Pulse only on count change (didUpdateWidget), not on first build — avoids extra tickers on load
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count &&
        AppAnimations.animationsEnabled(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badgeSize = widget.size ?? 20.0;
    final count = widget.count;

    if (count <= 0 && !widget.showZero) {
      return const SizedBox.shrink();
    }

    final displayCount = count > 99 ? '99+' : count.toString();
    final content = Container(
      width: badgeSize,
      height: badgeSize,
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      decoration: BoxDecoration(
        color: AppColors.notificationRed,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.notificationRed.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayCount,
          style: AppTypography.caption.copyWith(
            color: Colors.white,
            fontSize: count > 99 ? 8 : 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
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
