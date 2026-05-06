import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

void main() {
  group('userTierFromPlan', () {
    test('defaults to basid', () {
      expect(userTierFromPlan(), UserTier.basid);
      expect(userTierFromPlan(planId: 1, planName: 'Free'), UserTier.basid);
      expect(userTierFromPlan(planName: 'basic'), UserTier.basid);
      expect(userTierFromPlan(planName: 'bronze base'), UserTier.basid);
    });

    test('maps to silder', () {
      expect(userTierFromPlan(planId: 2), UserTier.silder);
      expect(userTierFromPlan(planName: 'Silver'), UserTier.silder);
      expect(userTierFromPlan(planName: 'Premium Monthly'), UserTier.silder);
    });

    test('maps to golden', () {
      expect(userTierFromPlan(planId: 3), UserTier.golden);
      expect(userTierFromPlan(planName: 'Golden'), UserTier.golden);
      expect(userTierFromPlan(planName: 'Gold Plan'), UserTier.golden);
    });
  });

  group('UserTier ordering', () {
    test('atLeast respects ordering', () {
      expect(UserTier.basid.atLeast(UserTier.basid), isTrue);
      expect(UserTier.basid.atLeast(UserTier.silder), isFalse);
      expect(UserTier.silder.atLeast(UserTier.basid), isTrue);
      expect(UserTier.golden.atLeast(UserTier.silder), isTrue);
    });
  });
}

