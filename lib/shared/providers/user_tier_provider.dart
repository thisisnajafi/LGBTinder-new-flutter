import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/session_cache_providers.dart';
import '../../features/payments/data/models/plan_limits.dart';
import '../../features/payments/providers/payment_providers.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../models/user_tier.dart';
import '../../core/providers/subscription_provider.dart';

/// Best-effort tier provider (does not throw):
/// - prefers global [subscriptionProvider] (synced on every API response)
/// - then cached `user:tier`
/// - then `PlanLimits.planInfo`
/// - falls back to legacy `SubscriptionStatus`
final userTierProvider = Provider<UserTier>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  if (subscription != null) {
    return subscription.tier;
  }

  final cachedTier = ref.watch(cachedUserTierProvider);
  if (cachedTier != null) {
    return UserTier.values.firstWhere(
      (t) => t.key == cachedTier,
      orElse: () => UserTier.basid,
    );
  }

  final planLimits = ref.watch(planLimitsProvider).valueOrNull;
  if (planLimits != null) {
    final apiTier = planLimits.planInfo.tier?.toLowerCase().trim();
    if (apiTier != null && apiTier.isNotEmpty) {
      return UserTier.values.firstWhere(
        (t) => t.key == apiTier,
        orElse: () => userTierFromPlan(
          planId: planLimits.planInfo.planId,
          planName: planLimits.planInfo.planName,
        ),
      );
    }
    return userTierFromPlan(
      planId: planLimits.planInfo.planId,
      planName: planLimits.planInfo.planName,
    );
  }

  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  if (status != null) {
    return userTierFromPlan(planId: status.planId, planName: status.planName);
  }

  return UserTier.basid;
});

/// Feature-aware guards — prefer [subscriptionProvider.notifier] getters in UI.
final subscriptionAccessProvider = Provider<SubscriptionNotifier>((ref) {
  return ref.watch(subscriptionProvider.notifier);
});

/// Helper for guarding features/pages by tier.
bool tierAllows(UserTier current, {required UserTier min}) => current.atLeast(min);

/// Convenience: interpret plan limits features into a minimum tier requirement.
///
/// This is intentionally conservative (if limits say a feature is enabled, we allow it even if tier is unknown).
bool featureAllowsByLimits(PlanLimits? limits, String featureName) {
  if (limits == null) return false;
  return limits.hasFeature(featureName);
}
