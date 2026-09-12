import 'package:flutter/material.dart';

import '../../profile/data/models/update_profile_request.dart';
import '../../reference_data/data/models/reference_item.dart';

/// Reference rows shown on [OnboardingPreferencesScreen].
class OnboardingPreferenceOptions {
  const OnboardingPreferenceOptions({
    this.preferredGenders = const [],
    this.relationGoals = const [],
    this.interests = const [],
  });

  final List<ReferenceItem> preferredGenders;
  final List<ReferenceItem> relationGoals;
  final List<ReferenceItem> interests;
}

/// Local preference snapshot. Chip/slider edits stay here until Save
/// (PERF-SCR-ONBPREF-002) so we issue one [UpdateProfileRequest].
class OnboardingPreferencesDraft {
  const OnboardingPreferencesDraft({
    this.preferredGenderIds = const [],
    this.ageRange = const RangeValues(18, 100),
    this.maxDistance = 50,
    this.relationGoalIds = const [],
    this.interestIds = const [],
  });

  final List<int> preferredGenderIds;
  final RangeValues ageRange;
  final double maxDistance;
  final List<int> relationGoalIds;
  final List<int> interestIds;

  static const int minInterestCount = 3;

  bool get hasMinimumInterests => interestIds.length >= minInterestCount;

  UpdateProfileRequest toUpdateProfileRequest() {
    return UpdateProfileRequest(
      preferredGenders:
          preferredGenderIds.isNotEmpty ? List<int>.from(preferredGenderIds) : null,
      minAgePreference: ageRange.start.round(),
      maxAgePreference: ageRange.end.round(),
      relationGoals:
          relationGoalIds.isNotEmpty ? List<int>.from(relationGoalIds) : null,
      interests: interestIds.isNotEmpty ? List<int>.from(interestIds) : null,
    );
  }
}

/// Immutable toggle used by chip notifiers (new list so listeners fire).
List<int> togglePreferenceId(List<int> current, int id) {
  final next = List<int>.from(current);
  if (!next.remove(id)) {
    next.add(id);
  }
  return next;
}
