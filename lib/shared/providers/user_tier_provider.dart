import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/payments/data/models/plan_limits.dart';
import '../../features/payments/providers/payment_providers.dart';
import '../../features/payments/data/services/plan_limits_service.dart';
import '../models/user_tier.dart';

/// Best-effort tier provider (does not throw):
/// - prefers `PlanLimits.planInfo` (authoritative for features)
/// - falls back to `SubscriptionStatus`
final userTierProvider = Provider<UserTier>((ref) {
  final planLimits = ref.watch(planLimitsProvider).valueOrNull;
  if (planLimits != null) {
    return userTierFromPlan(planId: planLimits.planInfo.planId, planName: planLimits.planInfo.planName);
  }

  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  if (status != null) {
    return userTierFromPlan(planId: status.planId, planName: status.planName);
  }

  return UserTier.basid;
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

