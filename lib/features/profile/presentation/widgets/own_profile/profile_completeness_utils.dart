import '../../../data/models/user_profile.dart';

/// Local profile completeness (no API).
class ProfileCompletenessResult {
  final int percent;
  final String? firstTip;
  final bool isComplete;

  const ProfileCompletenessResult({
    required this.percent,
    this.firstTip,
    required this.isComplete,
  });
}

ProfileCompletenessResult computeProfileCompleteness(UserProfile profile) {
  var score = 0;
  final tips = <String>[];

  final photoCount = profile.images?.length ?? 0;
  if (photoCount >= 2) {
    score += 25;
  } else {
    tips.add('Add more photos to attract attention');
  }

  final bio = profile.profileBio?.trim() ?? '';
  if (bio.isNotEmpty) {
    score += 25;
  } else {
    tips.add('Add a bio to get 3× more matches');
  }

  final interestCount =
      profile.interestTitles?.length ?? profile.interests?.length ?? 0;
  if (interestCount >= 3) {
    score += 20;
  } else {
    tips.add('Add your interests to find better matches');
  }

  final hasJobOrEducation =
      (profile.jobTitles != null && profile.jobTitles!.isNotEmpty) ||
      (profile.educationTitles != null && profile.educationTitles!.isNotEmpty) ||
      (profile.jobs != null && profile.jobs!.isNotEmpty) ||
      (profile.educations != null && profile.educations!.isNotEmpty);
  if (hasJobOrEducation) {
    score += 15;
  } else {
    tips.add('Add your job or education');
  }

  final hasLocation =
      (profile.city != null && profile.city!.isNotEmpty) ||
      (profile.country != null && profile.country!.isNotEmpty);
  if (hasLocation) {
    score += 15;
  } else {
    tips.add('Set your location');
  }

  return ProfileCompletenessResult(
    percent: score.clamp(0, 100),
    firstTip: tips.isEmpty ? null : tips.first,
    isComplete: score >= 100,
  );
}
