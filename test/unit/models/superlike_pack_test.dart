import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/payments/data/models/superlike_pack.dart';

void main() {
  group('SuperlikePack.fromJson', () {
    test('parses backend quantity and numeric price fields', () {
      final pack = SuperlikePack.fromJson({
        'id': 1,
        'name': '50 Superlikes',
        'quantity': 50,
        'price': 10.0,
        'currency': 'USD',
        'description': 'Get 50 extra superlikes',
      });

      expect(pack.id, 1);
      expect(pack.name, '50 Superlikes');
      expect(pack.superlikeCount, 50);
      expect(pack.price, 10.0);
      expect(pack.currency, 'USD');
    });

    test('parses string prices from Laravel decimal cast', () {
      final pack = SuperlikePack.fromJson({
        'id': 2,
        'name': '10 Superlikes',
        'quantity': '10',
        'price': '9.99',
        'discounted_price': '8.99',
        'currency': 'USD',
      });

      expect(pack.superlikeCount, 10);
      expect(pack.price, 9.99);
    });
  });
}
