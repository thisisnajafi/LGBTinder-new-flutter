import 'dart:async';

import '../../features/payments/data/models/plan_limits.dart';
import '../../features/payments/data/models/subscription_plan.dart';
import '../subscription/subscription_access.dart';
import '../../shared/models/subscription_status.dart';

/// Bridges Dio interceptors (no Ref) to Riverpod + disk cache.
class SubscriptionMetaSync {
  SubscriptionMetaSync._();

  static final SubscriptionMetaSync instance = SubscriptionMetaSync._();

  void Function(AppSubscriptionStatus status)? onUpdate;
  Future<void> Function(AppSubscriptionStatus status)? onCache;

  void handle(Map<String, dynamic> subscriptionJson) {
    try {
      final status = AppSubscriptionStatus.fromJson(subscriptionJson);
      unawaited(onCache?.call(status));
      onUpdate?.call(status);
    } catch (_) {
      // Never block API responses on parse failures.
    }
  }

  /// Sync from GET /subscriptions/status (legacy payment model).
  void syncFromLegacy(
    SubscriptionStatus status, {
    PlanLimits? planLimits,
  }) {
    final appStatus = appSubscriptionFromLegacy(status, planLimits: planLimits);
    unawaited(onCache?.call(appStatus));
    onUpdate?.call(appStatus);
  }
}
