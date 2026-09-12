import 'package:flutter/material.dart';

/// Shared scroll physics and cache extents (PERF-INFRA-020 / 023).
///
/// Default pull-to-refresh (PERF-SCR-PTR-001): pair these physics with
/// [PremiumRefreshIndicator] (`triggerMode: onEdge`, violet spinner, haptic
/// click). Do not use nested scroll views for settings/list hubs.
abstract final class AppScroll {
  static const ScrollPhysics bouncing = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  static const ScrollPhysics clamping = AlwaysScrollableScrollPhysics(
    parent: ClampingScrollPhysics(),
  );

  /// Off-screen pixels for forward lists ([AppListView]).
  static const double listCacheExtentPixels = 400;

  /// Off-screen pixels to keep built in a chat thread (~two viewports).
  static const double chatThreadCacheExtentPixels = 1000;

  /// Clamping on Android/desktop; bouncing on iOS/macOS (PERF-INFRA-023).
  static ScrollPhysics forPlatform(BuildContext context) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return bouncing;
      default:
        return clamping;
    }
  }

  /// Chat thread and messenger lists.
  static ScrollPhysics forChat(BuildContext context) => forPlatform(context);
}

/// Status-bar inset that still works when Android edge-to-edge reports padding.top = 0.
class PremiumSafeArea extends StatelessWidget {
  const PremiumSafeArea({
    super.key,
    required this.child,
    this.bottom = false,
  });

  final Widget child;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final missingTop = padding.top <= 0 && viewPadding.top > 0;

    return Padding(
      padding: EdgeInsets.only(top: missingTop ? viewPadding.top : 0),
      child: SafeArea(
        top: !missingTop,
        bottom: bottom,
        child: child,
      ),
    );
  }
}
