import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/data/repositories/analytics_repository.dart';

/// Lightweight funnel event tracker.
///
/// Sends events in the background with a short timeout and no retries so login
/// and other critical flows are never blocked by analytics.
class AppEventTracker {
  final Ref _ref;

  AppEventTracker(this._ref);

  /// Fire-and-forget — returns immediately; never blocks the caller.
  void track(String action, {Map<String, dynamic>? meta}) {
    unawaited(_trackSilently(action, meta));
  }

  Future<void> _trackSilently(
    String action,
    Map<String, dynamic>? meta,
  ) async {
    try {
      await _ref.read(analyticsRepositoryProvider).trackActivity(
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

