import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/shared/models/user_tier.dart';
import 'package:lgbtindernew/shared/providers/user_tier_provider.dart';

void main() {
  group('tierAllows', () {
    test('basid access matrix', () {
      expect(tierAllows(UserTier.basid, min: UserTier.basid), isTrue);
      expect(tierAllows(UserTier.basid, min: UserTier.silder), isFalse);
      expect(tierAllows(UserTier.basid, min: UserTier.golden), isFalse);
    });

    test('silder access matrix', () {
      expect(tierAllows(UserTier.silder, min: UserTier.basid), isTrue);
      expect(tierAllows(UserTier.silder, min: UserTier.silder), isTrue);
      expect(tierAllows(UserTier.silder, min: UserTier.golden), isFalse);
    });

    test('golden access matrix', () {
      expect(tierAllows(UserTier.golden, min: UserTier.basid), isTrue);
      expect(tierAllows(UserTier.golden, min: UserTier.silder), isTrue);
      expect(tierAllows(UserTier.golden, min: UserTier.golden), isTrue);
    });
  });
}

