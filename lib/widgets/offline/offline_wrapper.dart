// Widget: OfflineWrapper
// Offline state wrapper
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../offline/offline_indicator.dart';
import '../error_handling/empty_state.dart';

/// Offline wrapper widget
/// Wraps content and shows offline indicator when device is offline
class OfflineWrapper extends ConsumerWidget {
  final Widget child;
  final bool isOnline;
  final bool showOfflineScreen;

  const OfflineWrapper({
    Key? key,
    required this.child,
    required this.isOnline,
    this.showOfflineScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOnline && showOfflineScreen) {
      return EmptyState(
        title: 'No Internet Connection',
        message: 'Please check your connection and try again',
        icon: Icons.wifi_off,
      );
    }

    return Column(
      children: [
        OfflineIndicator(isOnline: isOnline),
        Expanded(child: child),
      ],
    );
  }
}
