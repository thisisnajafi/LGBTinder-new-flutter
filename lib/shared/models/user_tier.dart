enum UserTier {
  basid,
  silder,
  golden,
}

extension UserTierX on UserTier {
  String get key => switch (this) {
        UserTier.basid => 'basic',
        UserTier.silder => 'silder',
        UserTier.golden => 'golden',
      };

  /// User-facing label for badges and upgrade copy.
  /// Internal keys stay `silder` and `golden` (legacy slugs shared with the
  /// backend and the store catalog); the product names are Basic, Premium
  /// and Gold. "Silver" is a retired name for Premium.
  String get displayLabel => switch (this) {
        UserTier.basid => 'Basic',
        UserTier.silder => 'Premium',
        UserTier.golden => 'Gold',
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
/// - 2 or "premium" (legacy "silver"/"silder") => silder (Premium)
/// - 3 or "gold"/"golden" => golden
UserTier userTierFromPlan({int? planId, String? planName}) {
  final name = (planName ?? '').toLowerCase().trim();

  if (planId == 3 ||
      name.contains('golden') ||
      name.contains('gold') ||
      name.contains(' gold')) {
    return UserTier.golden;
  }
  if (planId == 2 ||
      name.contains('silver') ||
      name.contains('silder') ||
      name.contains('premium')) {
    return UserTier.silder;
  }
  return UserTier.basid;
}

/// Parse tier slug from API responses (`basic`, legacy `basid`, etc.).
UserTier userTierFromApiKey(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'basic':
    case 'basid':
    case 'bronze':
    case 'free':
      return UserTier.basid;
    case 'silder':
    case 'silver':
    case 'premium':
      return UserTier.silder;
    case 'golden':
    case 'gold':
      return UserTier.golden;
    default:
      return UserTier.basid;
  }
}


/// User-facing plan name for a backend tier slug or plan title.
///
/// The plans are Free (no subscription), Basic, Premium and Gold. Legacy
/// names from the store catalog / database map onto them: "Silver"/"silder"
/// => Premium, "Golden" => Gold, "Bronze"/"basid" => Basic.
String planDisplayName(String? raw) {
  final v = (raw ?? '').toLowerCase().trim();
  if (v.isEmpty || v == 'free' || v == 'none' || v.contains('free plan')) {
    return 'Free';
  }
  if (v.contains('gold')) return 'Gold';
  if (v.contains('premium') || v.contains('silver') || v.contains('silder')) {
    return 'Premium';
  }
  if (v.contains('basic') || v.contains('basid') || v.contains('bronze')) {
    return 'Basic';
  }
  return raw!.trim();
}

/// Paid tier for a backend plan id (1 = Basic, 2 = Premium, 3 = Gold).
UserTier? userTierFromPlanId(int? planId) => switch (planId) {
      1 => UserTier.basid,
      2 => UserTier.silder,
      3 => UserTier.golden,
      _ => null,
    };
