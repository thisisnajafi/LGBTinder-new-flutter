import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/app_haptics.dart';

/// Pull-to-refresh chrome from the other-user profile:
/// light circular badge, violet indicator, bounce physics.
///
/// Default for list hubs (PERF-SCR-PTR-001): `onEdge` trigger, no elevation,
/// haptic via [AppHaptics] (respects the global haptic gate).
class PremiumRefreshIndicator extends StatelessWidget {
  const PremiumRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final double edgeOffset;
  final ScrollNotificationPredicate notificationPredicate;

  /// Lets a header + nested list (tab/detail scaffolds) trigger refresh.
  static bool nested(ScrollNotification notification) => true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        AppHaptics.selection();
        await onRefresh();
      },
      color: AppColors.accentViolet,
      backgroundColor:
          isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
      elevation: 0,
      displacement: 48,
      edgeOffset: edgeOffset,
      strokeWidth: 2.4,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      notificationPredicate: notificationPredicate,
      child: child,
    );
  }
}

/// Wraps a header + body so nested lists can pull-to-refresh with the profile indicator.
class PremiumRefreshScope extends StatelessWidget {
  const PremiumRefreshScope({
    super.key,
    required this.onRefresh,
    required this.header,
    required this.body,
  });

  final RefreshCallback onRefresh;
  final Widget header;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return PremiumRefreshIndicator(
      onRefresh: onRefresh,
      notificationPredicate: PremiumRefreshIndicator.nested,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: body),
        ],
      ),
    );
  }
}
