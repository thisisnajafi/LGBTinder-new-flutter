import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/onboarding/utils/onboarding_preferences_draft.dart';
import 'package:lgbtindernew/features/profile/data/models/update_profile_request.dart';

void main() {
  test('togglePreferenceId adds and removes without mutating the original', () {
    const original = [1, 2];
    final added = togglePreferenceId(original, 3);
    expect(added, [1, 2, 3]);
    expect(original, [1, 2]);

    final removed = togglePreferenceId(added, 2);
    expect(removed, [1, 3]);
  });

  test('toUpdateProfileRequest batches all fields into one payload', () {
    const draft = OnboardingPreferencesDraft(
      preferredGenderIds: [10, 11],
      ageRange: RangeValues(21, 40),
      maxDistance: 25,
      relationGoalIds: [9],
      interestIds: [6, 7, 8],
    );

    expect(draft.hasMinimumInterests, isTrue);

    final UpdateProfileRequest request = draft.toUpdateProfileRequest();
    expect(request.preferredGenders, [10, 11]);
    expect(request.minAgePreference, 21);
    expect(request.maxAgePreference, 40);
    expect(request.relationGoals, [9]);
    expect(request.interests, [6, 7, 8]);
  });

  test('empty selections omit list fields and fail the interest minimum', () {
    const draft = OnboardingPreferencesDraft();
    expect(draft.hasMinimumInterests, isFalse);

    final request = draft.toUpdateProfileRequest();
    expect(request.preferredGenders, isNull);
    expect(request.relationGoals, isNull);
    expect(request.interests, isNull);
    expect(request.minAgePreference, 18);
    expect(request.maxAgePreference, 100);
  });
}
