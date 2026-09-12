import '../../profile/data/models/user_profile.dart';

/// Local form snapshot for [ProfileCompletionScreen] (PERF-SCR-PCOMP-001).
///
/// Built from [profilePageCacheProvider] on open — never from a blocking fetch.
class ProfileCompletionDraft {
  const ProfileCompletionDraft({
    this.avatarUrl,
    this.name = '',
    this.age,
    this.location = '',
    this.bio = '',
    this.imageUrls = const [],
    this.interests = const [],
    this.gender,
    this.preferredGenders,
  });

  final String? avatarUrl;
  final String name;
  final int? age;
  final String location;
  final String bio;
  final List<String> imageUrls;
  final List<String> interests;
  final String? gender;
  final List<String>? preferredGenders;

  static const int trackedFieldCount = 8;

  factory ProfileCompletionDraft.fromProfile(UserProfile profile) {
    final images = List.of(profile.images ?? const [])
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) {
          return a.isPrimary ? -1 : 1;
        }
        return a.order.compareTo(b.order);
      });
    final urls = <String>[
      for (final image in images)
        if (image.url.isNotEmpty) image.url,
    ];
    final avatar = images.isEmpty ? null : images.first;

    final locationParts = <String>[
      if ((profile.city ?? '').trim().isNotEmpty) profile.city!.trim(),
      if ((profile.country ?? '').trim().isNotEmpty) profile.country!.trim(),
    ];

    return ProfileCompletionDraft(
      avatarUrl: avatar?.avatarDisplayUrl,
      name: '${profile.firstName} ${profile.lastName}'.trim(),
      age: ageFromBirthDate(profile.birthDate),
      location: locationParts.join(', '),
      bio: profile.profileBio ?? '',
      imageUrls: urls,
      interests: List<String>.from(profile.interestTitles ?? const []),
      gender: profile.gender,
      preferredGenders:
          profile.preferredGenders?.map((id) => id.toString()).toList(),
    );
  }

  int get percent {
    var completed = 0;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) completed++;
    if (name.isNotEmpty) completed++;
    if (age != null) completed++;
    if (location.isNotEmpty) completed++;
    if (bio.isNotEmpty) completed++;
    if (imageUrls.length >= 3) completed++;
    if (interests.isNotEmpty) completed++;
    if (gender != null && gender!.isNotEmpty) completed++;
    return ((completed / trackedFieldCount) * 100).round();
  }

  ProfileCompletionDraft copyWith({
    String? avatarUrl,
    String? name,
    int? age,
    String? location,
    String? bio,
    List<String>? imageUrls,
    List<String>? interests,
    String? gender,
    List<String>? preferredGenders,
  }) {
    return ProfileCompletionDraft(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      name: name ?? this.name,
      age: age ?? this.age,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      imageUrls: imageUrls ?? this.imageUrls,
      interests: interests ?? this.interests,
      gender: gender ?? this.gender,
      preferredGenders: preferredGenders ?? this.preferredGenders,
    );
  }
}

/// Age in full years from an API `YYYY-MM-DD` (or ISO) birth date.
int? ageFromBirthDate(String? birthDate) {
  if (birthDate == null || birthDate.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(birthDate.trim());
  if (parsed == null) return null;
  final now = DateTime.now();
  var age = now.year - parsed.year;
  if (now.month < parsed.month ||
      (now.month == parsed.month && now.day < parsed.day)) {
    age--;
  }
  return age < 0 ? null : age;
}
