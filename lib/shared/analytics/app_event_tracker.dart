import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/providers/analytics_provider.dart';

/// Lightweight funnel event tracker.
///
/// Uses existing backend analytics endpoint via `analyticsProvider.trackActivity`.
/// Never throws (so UX is never blocked by analytics failures).
class AppEventTracker {
  final Ref _ref;

  AppEventTracker(this._ref);

  Future<void> track(String action, {Map<String, dynamic>? meta}) async {
    try {
      await _ref.read(analyticsProvider.notifier).trackActivity(
            action: action,
            metadata: meta ?? const {},
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📊 track("$action") failed: $e');
      }
    }
  }
}

final appEventTrackerProvider = Provider<AppEventTracker>((ref) {
  return AppEventTracker(ref);
});

