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
      expect(userTierFromPlan(planName: 'Silder'), UserTier.silder);
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

  group('userTierFromApiKey', () {
    test('parses basic and legacy basid', () {
      expect(userTierFromApiKey('basic'), UserTier.basid);
      expect(userTierFromApiKey('basid'), UserTier.basid);
      expect(userTierFromApiKey('silder'), UserTier.silder);
      expect(userTierFromApiKey('premium'), UserTier.silder);
      expect(userTierFromApiKey('silver'), UserTier.silder);
      expect(userTierFromApiKey('golden'), UserTier.golden);
    });

    test('display label for basic tier', () {
      expect(UserTier.basid.key, 'basic');
      expect(UserTier.basid.displayLabel, 'Basic');
    });
  });
}

