import 'user_tier.dart';

/// App features/pages with explicit minimum tier access.
enum TierGatedFeature {
  likesYou,
  advancedFilters,
  videoCalls,
  boost,
}

UserTier minimumTierForFeature(TierGatedFeature feature) {
  switch (feature) {
    case TierGatedFeature.likesYou:
      return UserTier.silder;
    case TierGatedFeature.advancedFilters:
      return UserTier.silder;
    case TierGatedFeature.videoCalls:
      return UserTier.silder;
    case TierGatedFeature.boost:
      return UserTier.golden;
  }
}

bool canAccessFeature(UserTier currentTier, TierGatedFeature feature) {
  return currentTier.atLeast(minimumTierForFeature(feature));
}
