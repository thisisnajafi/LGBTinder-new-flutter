import 'dart:async';

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
}
