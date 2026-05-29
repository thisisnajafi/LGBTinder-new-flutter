enum UserTier {
  basid,
  silder,
  golden,
}

extension UserTierX on UserTier {
  String get key => switch (this) {
        UserTier.basid => 'basid',
        UserTier.silder => 'silder',
        UserTier.golden => 'golden',
      };

  /// Numeric ordering for comparisons (higher = more access).
  int get level => switch (this) {
        UserTier.basid => 1,
        UserTier.silder => 2,
        UserTier.golden => 3,
      };

  bool atLeast(UserTier other) => level >= other.level;
}

/// Derive tier from backend plan identifiers.
///
/// Sources:
/// - `SubscriptionStatus.planId/planName`
/// - `PlanLimits.planInfo.planId/planName`
///
/// Mapping:
/// - 1 or "bronze"/"basic" => basid
/// - 2 or "silver"/"premium" => silder
/// - 3 or "gold"/"golden" => golden
UserTier userTierFromPlan({int? planId, String? planName}) {
  final name = (planName ?? '').toLowerCase().trim();

  if (planId == 3 ||
      name.contains('golden') ||
      name.contains('gold') ||
      name.contains(' gold')) {
    return UserTier.golden;
  }
  if (planId == 2 || name.contains('silver') || name.contains('premium')) {
    return UserTier.silder;
  }
  return UserTier.basid;
}

