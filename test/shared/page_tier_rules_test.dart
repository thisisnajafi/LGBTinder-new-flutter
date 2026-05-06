import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/models/page_tier_rules.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

void main() {
  group('Page/feature tier matrix', () {
    test('basid access matrix', () {
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.likesYou), isFalse);
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.advancedFilters), isFalse);
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.videoCalls), isFalse);
      expect(canAccessFeature(UserTier.basid, TierGatedFeature.boost), isFalse);
    });

    test('silder access matrix', () {
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.likesYou), isTrue);
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.advancedFilters), isTrue);
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.videoCalls), isTrue);
      expect(canAccessFeature(UserTier.silder, TierGatedFeature.boost), isFalse);
    });

    test('golden access matrix', () {
      for (final feature in TierGatedFeature.values) {
        expect(canAccessFeature(UserTier.golden, feature), isTrue);
      }
    });
  });
}
