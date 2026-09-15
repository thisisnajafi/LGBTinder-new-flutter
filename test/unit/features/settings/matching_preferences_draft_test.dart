import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/settings/data/models/matching_preferences.dart';
import 'package:lgbtindernew/features/settings/utils/matching_preferences_draft.dart';

void main() {
  group('clampMatchingAgeRange', () {
    test('orders inverted thumbs', () {
      final clamped = clampMatchingAgeRange(const RangeValues(40, 22));
      expect(clamped.start, 22);
      expect(clamped.end, 40);
    });

    test('clamps outside 18–100', () {
      final clamped = clampMatchingAgeRange(const RangeValues(1, 140));
      expect(clamped.start, kMatchingAgeMin);
      expect(clamped.end, kMatchingAgeMax);
    });
  });

  test('draft toPreferences uses notifier values', () {
    final draft = MatchingPreferencesDraft();
    addTearDown(draft.dispose);

    draft.ageRange.value = const RangeValues(21, 35);
    draft.distance.value = clampMatchingDistance(12.4);
    draft.visibility.value = 'hidden';

    final prefs = draft.toPreferences();
    expect(prefs.ageMin, 21);
    expect(prefs.ageMax, 35);
    expect(prefs.distance, 12);
    expect(prefs.discoveryVisibility, 'hidden');
  });

  test('apply copies MatchingPreferences into notifiers', () {
    final draft = MatchingPreferencesDraft();
    addTearDown(draft.dispose);

    draft.apply(
      const MatchingPreferences(
        ageMin: 25,
        ageMax: 40,
        distance: 80,
        discoveryVisibility: 'people_i_like',
      ),
    );

    expect(draft.ageRange.value.start, 25);
    expect(draft.ageRange.value.end, 40);
    expect(draft.distance.value, 80);
    expect(draft.visibility.value, 'people_i_like');
  });
}
