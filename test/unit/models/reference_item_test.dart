import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/reference_data/data/models/reference_item.dart';

void main() {
  group('ReferenceItem.uniqueByTitle', () {
    test('keeps one city per name and prefers coordinates', () {
      final cities = [
        ReferenceItem(id: 1, title: 'Atlanta', stateProvince: 'Texas'),
        ReferenceItem(
          id: 2,
          title: 'Atlanta',
          stateProvince: 'Georgia',
          latitude: 33.749,
          longitude: -84.388,
        ),
        ReferenceItem(id: 3, title: 'Austin', latitude: 30.267, longitude: -97.743),
        ReferenceItem(id: 4, title: 'Atlanta', stateProvince: 'Illinois'),
      ];

      final unique = ReferenceItem.uniqueByTitle(cities);

      expect(unique.map((c) => c.title), ['Atlanta', 'Austin']);
      expect(unique.first.id, 2);
    });
  });
}
