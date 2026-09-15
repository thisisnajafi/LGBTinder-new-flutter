import 'package:flutter/material.dart';

import '../data/models/matching_preferences.dart';

const int kMatchingAgeMin = 18;
const int kMatchingAgeMax = 100;
const double kMatchingDistanceMin = 1;
const double kMatchingDistanceMax = 500;

/// Clamp an age [RangeSlider] so start/end stay within 18–100 and ordered.
RangeValues clampMatchingAgeRange(RangeValues values) {
  final start = values.start.round().clamp(kMatchingAgeMin, kMatchingAgeMax);
  final end = values.end.round().clamp(kMatchingAgeMin, kMatchingAgeMax);
  if (start <= end) {
    return RangeValues(start.toDouble(), end.toDouble());
  }
  return RangeValues(end.toDouble(), start.toDouble());
}

double clampMatchingDistance(double value) {
  return value.clamp(kMatchingDistanceMin, kMatchingDistanceMax).roundToDouble();
}

/// Local discovery-pref snapshot. Slider/visibility edits stay here until Save
/// (PERF-FEAT-SET-003) so drags do not rebuild the rest of the screen.
class MatchingPreferencesDraft {
  MatchingPreferencesDraft({
    int ageMin = kMatchingAgeMin,
    int ageMax = kMatchingAgeMax,
    double distance = 50,
    String discoveryVisibility = 'everyone',
  })  : ageRange = ValueNotifier(
          RangeValues(ageMin.toDouble(), ageMax.toDouble()),
        ),
        distance = ValueNotifier(clampMatchingDistance(distance)),
        visibility = ValueNotifier(discoveryVisibility);

  final ValueNotifier<RangeValues> ageRange;
  final ValueNotifier<double> distance;
  final ValueNotifier<String> visibility;

  void apply(MatchingPreferences prefs) {
    ageRange.value = clampMatchingAgeRange(
      RangeValues(prefs.ageMin.toDouble(), prefs.ageMax.toDouble()),
    );
    distance.value = clampMatchingDistance(prefs.distance);
    visibility.value = prefs.discoveryVisibility;
  }

  void resetAgeRange() {
    ageRange.value = const RangeValues(18, 100);
  }

  MatchingPreferences toPreferences() {
    final range = ageRange.value;
    return MatchingPreferences(
      ageMin: range.start.round(),
      ageMax: range.end.round(),
      distance: distance.value,
      discoveryVisibility: visibility.value,
    );
  }

  void dispose() {
    ageRange.dispose();
    distance.dispose();
    visibility.dispose();
  }
}
