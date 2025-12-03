// Widget: NotificationBadge
// Notification count badge
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing_constants.dart';
import '../../core/theme/border_radius_constants.dart';

/// Notification count badge widget
/// Displays a red circular badge with notification count
class NotificationBadge extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final badgeSize = size ?? 20.0;

    if (count <= 0 && !showZero) {
      return const SizedBox.shrink();
    }

    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
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
  }
}
