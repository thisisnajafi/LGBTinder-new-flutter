import 'dart:async';

import '../../features/payments/data/models/plan_limits.dart';
import '../../features/payments/data/models/subscription_plan.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/user_tier.dart';
import '../services/app_logger.dart';
import '../subscription/subscription_access.dart';

/// Bridges Dio interceptors (no Ref) to Riverpod + disk cache.
class SubscriptionMetaSync {
  SubscriptionMetaSync._();

  static final SubscriptionMetaSync instance = SubscriptionMetaSync._();

  void Function(AppSubscriptionStatus status)? onUpdate;
  Future<void> Function(AppSubscriptionStatus status)? onCache;
  String? _lastTierKey;

  void handle(Map<String, dynamic> subscriptionJson) {
    try {
      final status = AppSubscriptionStatus.fromJson(subscriptionJson);
      final nextKey = status.tier.key;
      if (_lastTierKey != nextKey) {
        AppLogger.debug(
          'Subscription tier ${_lastTierKey ?? 'none'} → $nextKey',
          tag: 'SubscriptionInterceptor',
        );
        _lastTierKey = nextKey;
      }
      unawaited(onCache?.call(status));
      onUpdate?.call(status);
    } catch (e) {
      AppLogger.error(
        'Subscription meta parse failed',
        tag: 'SubscriptionInterceptor',
        error: e,
      );
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
