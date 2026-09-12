import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/calls/data/models/call_initiate_exception.dart';
import 'package:lgbtindernew/features/calls/data/models/call_statistics.dart';

void main() {
  group('CallEligibility.fromJson', () {
    test('reads nested and top-level can_call', () {
      final eligibility = CallEligibility.fromJson({
        'can_call': true,
        'reason': null,
        'is_premium_required': false,
        'is_match_required': false,
      });

      expect(eligibility.canCall, isTrue);
      expect(eligibility.isPremiumRequired, isFalse);
    });

    test('treats denied plan as upgrade required from flags', () {
      final eligibility = CallEligibility.fromJson({
        'can_call': false,
        'reason': 'Voice and video calls are not included on the Free plan. Please upgrade to start calling.',
        'is_premium_required': true,
        'is_match_required': false,
      });

      expect(eligibility.canCall, isFalse);
      expect(eligibility.isPremiumRequired, isTrue);
      expect(
        CallInitiateException(
          eligibility.reason!,
          upgradeRequired: eligibility.isPremiumRequired,
        ).upgradeRequired,
        isTrue,
      );
    });
  });
}
