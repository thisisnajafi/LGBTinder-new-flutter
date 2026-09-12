import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';
import 'package:lgbtindernew/features/profile/domain/profile_plan_resolver.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';

UserProfile _profile(Map<String, dynamic> extra) {
  return UserProfile.fromJson({
    'id': 1,
    'first_name': 'Abolfazl',
    'last_name': 'Najafi',
    'email': 'a@b.c',
    ...extra,
  });
}

void main() {
  group('tierFromUserProfile', () {
    test('uses plan_type Premium from other-user API payload', () {
      final profile = _profile({'plan_type': 'Premium'});
      expect(tierFromUserProfile(profile), UserTier.silder);
      expect(planBadgeLabelFromUserProfile(profile), 'Premium');
    });

    test('uses plan_type Golden', () {
      final profile = _profile({'plan_type': 'Golden', 'is_premium': true});
      expect(tierFromUserProfile(profile), UserTier.golden);
      expect(planBadgeLabelFromUserProfile(profile), 'Golden');
    });

    test('falls back to is_premium when plan title is missing', () {
      final profile = _profile({'is_premium': true});
      expect(tierFromUserProfile(profile), UserTier.silder);
      expect(planBadgeLabelFromUserProfile(profile), 'Silver');
    });

    test('defaults to Basic when there is no paid plan', () {
      final profile = _profile({});
      expect(tierFromUserProfile(profile), UserTier.basid);
      expect(planBadgeLabelFromUserProfile(profile), 'Basic');
    });

    test('normalizes legacy Silder title to Silver', () {
      final profile = _profile({'plan_type': 'Silder'});
      expect(tierFromUserProfile(profile), UserTier.silder);
      expect(planBadgeLabelFromUserProfile(profile), 'Silver');
    });
  });
}
