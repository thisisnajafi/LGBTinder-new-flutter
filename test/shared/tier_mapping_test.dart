import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/screens/feature_locked_screen.dart';
import 'package:lgbtindernew/screens/tier_comparison_screen.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';
import 'package:lgbtindernew/shared/utils/plan_guard.dart';

void main() {
  group('tier mapping (Free < Basic < Premium < Gold)', () {
    test('legacy Silver / silder map to Premium; Golden to Gold', () {
      expect(userTierFromApiKey('silver'), UserTier.silder);
      expect(userTierFromApiKey('silder'), UserTier.silder);
      expect(userTierFromApiKey('premium'), UserTier.silder);
      expect(userTierFromApiKey('golden'), UserTier.golden);
      expect(userTierFromApiKey('gold'), UserTier.golden);
      expect(userTierFromApiKey('basic'), UserTier.basid);
    });

    test('display names use the real plan names', () {
      expect(UserTier.basid.displayLabel, 'Basic');
      expect(UserTier.silder.displayLabel, 'Premium');
      expect(UserTier.golden.displayLabel, 'Gold');
      expect(planDisplayName(null), 'Free');
      expect(planDisplayName('free'), 'Free');
      expect(planDisplayName('Silver'), 'Premium');
      expect(planDisplayName('silder'), 'Premium');
      expect(planDisplayName('Golden'), 'Gold');
      expect(planDisplayName('golden'), 'Gold');
      expect(planDisplayName('bronze'), 'Basic');
    });

    test('plan ids map 1/2/3 to Basic/Premium/Gold', () {
      expect(userTierFromPlanId(1), UserTier.basid);
      expect(userTierFromPlanId(2), UserTier.silder);
      expect(userTierFromPlanId(3), UserTier.golden);
      expect(userTierFromPlanId(null), isNull);
    });

    test('hierarchy: higher tiers include lower ones', () {
      expect(UserTier.golden.atLeast(UserTier.silder), isTrue);
      expect(UserTier.golden.atLeast(UserTier.basid), isTrue);
      expect(UserTier.silder.atLeast(UserTier.silder), isTrue);
      expect(UserTier.basid.atLeast(UserTier.silder), isFalse);
    });

    test('see who liked you unlocks at Premium, Gold included', () {
      expect(seeWhoLikedMeMinTier, UserTier.silder);
      expect(UserTier.golden.atLeast(seeWhoLikedMeMinTier), isTrue);
      expect(UserTier.basid.atLeast(seeWhoLikedMeMinTier), isFalse);
    });

    test('feature-locked minTier query parses legacy and new names', () {
      expect(FeatureLockedScreen.parseTier('silder'), UserTier.silder);
      expect(FeatureLockedScreen.parseTier('premium'), UserTier.silder);
      expect(FeatureLockedScreen.parseTier('gold'), UserTier.golden);
    });

    test('compare tiers lists Free, Basic, Premium, Gold without Silver', () {
      expect(tierComparisonCards.map((c) => c.title).toList(),
          ['Free', 'Basic', 'Premium', 'Gold']);
      final all = tierComparisonCards.expand((c) => c.bullets).join(' ');
      expect(all.contains('Silver'), isFalse);
      final gold = tierComparisonCards.last;
      expect(gold.bullets, contains('Video calls'));
      final premium = tierComparisonCards[2];
      expect(premium.bullets, contains('See who liked you'));
      expect(premium.bullets, contains('Voice calls'));
    });
  });
}
