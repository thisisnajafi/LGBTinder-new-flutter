import 'package:flutter_test/flutter_test.dart';
import 'package:lgbtindernew/features/auth/utils/profile_completion_draft.dart';
import 'package:lgbtindernew/features/profile/data/models/user_profile.dart';

void main() {
  test('empty draft is 0 percent', () {
    expect(const ProfileCompletionDraft().percent, 0);
  });

  test('fromProfile hydrates name, location, bio without a network call', () {
    const profile = UserProfile(
      id: 1,
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: 'ada@example.com',
      profileBio: 'Mathematician',
      city: 'London',
      country: 'UK',
      gender: 'Woman',
    );

    final draft = ProfileCompletionDraft.fromProfile(profile);

    expect(draft.name, 'Ada Lovelace');
    expect(draft.location, 'London, UK');
    expect(draft.bio, 'Mathematician');
    expect(draft.gender, 'Woman');
    expect(draft.percent, 50);
  });

  test('ageFromBirthDate uses full years', () {
    final now = DateTime.now();
    final birth = DateTime(now.year - 30, now.month, now.day);
    final iso =
        '${birth.year.toString().padLeft(4, '0')}-${birth.month.toString().padLeft(2, '0')}-${birth.day.toString().padLeft(2, '0')}';
    expect(ageFromBirthDate(iso), 30);
    expect(ageFromBirthDate(null), isNull);
  });
}
