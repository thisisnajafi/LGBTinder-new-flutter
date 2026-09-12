import 'package:flutter_test/flutter_test.dart';

import 'package:lgbtindernew/features/discover/utils/discover_active_filter_labels.dart';

void main() {
  test('empty map has no chips', () {
    expect(DiscoverActiveFilterLabels.fromMap(null), isEmpty);
    expect(DiscoverActiveFilterLabels.fromMap({}), isEmpty);
  });

  test('core chips cover distance, age, online, verified', () {
    expect(
      DiscoverActiveFilterLabels.fromMap({
        'max_distance': 25,
        'min_age': 21,
        'max_age': 35,
        'online_only': true,
        'verified_only': true,
      }),
      ['25km', '21–35', 'Online', 'Verified'],
    );
  });

  test('gender, interests, lifestyle and extra fields get labels', () {
    expect(
      DiscoverActiveFilterLabels.fromMap({
        'gender_ids': '1,2',
        'interest_ids': [9],
        'relation_goal_ids': [3, 4],
        'smoke': true,
        'city': 'Berlin',
        'premium_only': true,
      }),
      ['Premium', '2 genders', '1 interest', '2 goals', 'Lifestyle', 'Berlin'],
    );
  });

  test('unknown leftover keys still show Custom filters', () {
    expect(
      DiscoverActiveFilterLabels.fromMap({'foo': 'bar'}),
      ['Custom filters'],
    );
  });
}
