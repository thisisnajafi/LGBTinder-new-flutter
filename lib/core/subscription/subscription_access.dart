import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/payments/data/models/plan_limits.dart';
import '../../features/payments/data/models/subscription_plan.dart';
import '../../features/payments/providers/payment_providers.dart';
import '../../shared/models/subscription_status.dart';
import '../../shared/models/user_tier.dart';
import '../../shared/providers/user_tier_provider.dart';
import '../providers/subscription_provider.dart';

/// Whether advanced discovery filters are unlocked for the current user.
final hasAdvancedFiltersProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  if (sub?.features.advancedFilters == true || sub?.isPremium == true) {
    return true;
  }
  if (ref.watch(userTierProvider).atLeast(UserTier.silder)) {
    return true;
  }
  return ref.watch(planLimitsProvider).valueOrNull?.features.advancedFilters ??
      false;
});

/// Best-effort premium flag for UI gates.
final isPremiumUserProvider = Provider<bool>((ref) {
  final sub = ref.watch(subscriptionProvider);
  if (sub?.isPremium == true) return true;
  if (ref.watch(userTierProvider).atLeast(UserTier.silder)) return true;
  return ref.watch(planLimitsProvider).valueOrNull?.planInfo.isPremium ?? false;
});

/// Converts legacy payment [SubscriptionStatus] into global [AppSubscriptionStatus].
AppSubscriptionStatus appSubscriptionFromLegacy(
  SubscriptionStatus status, {
  PlanLimits? planLimits,
}) {
  final tierRaw = status.tier?.toLowerCase().trim();
  final tier = tierRaw != null && tierRaw.isNotEmpty
      ? UserTier.values.firstWhere(
          (t) => t.key == tierRaw,
          orElse: () => userTierFromPlan(
            planId: status.planId ?? planLimits?.planInfo.planId,
            planName: status.planName ?? planLimits?.planInfo.planName,
          ),
        )
      : userTierFromPlan(
          planId: status.planId ?? planLimits?.planInfo.planId,
          planName: status.planName ?? planLimits?.planInfo.planName,
        );

  final features = planLimits?.features;
  final isActive = status.isActive;

  return AppSubscriptionStatus(
    tier: tier,
    isActive: isActive,
    isPremium: isActive && tier != UserTier.basid,
    planName: status.planName ?? planLimits?.planInfo.planName,
    expiresAt: status.endDate ?? status.nextBillingDate,
    superlikesRemaining: planLimits?.effectiveSuperlikeInfo.totalRemaining ?? 0,
    features: SubscriptionFeatures(
      unlimitedLikes: tier.atLeast(UserTier.silder),
      seeWhoLikedYou: features?.seeWhoLikedMe ?? tier.atLeast(UserTier.silder),
      videoCalls: features?.videoCalls ?? tier == UserTier.golden,
      advancedFilters: features?.advancedFilters ?? tier.atLeast(UserTier.silder),
      profileBoost: features?.boost ?? tier.atLeast(UserTier.silder),
      chatMessagesVisible: null,
      messagesPerMatchDaily: null,
    ),
    refreshedAt: DateTime.now(),
  );
}
