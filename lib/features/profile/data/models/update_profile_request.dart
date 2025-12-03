/// Update profile request model
class UpdateProfileRequest {
  final String? profileBio;
  final int? height;
  final int? weight;
  final bool? smoke;
  final bool? drink;
  final bool? gym;
  final List<int>? musicGenres;
  final List<int>? educations;
  final List<int>? jobs;
  final List<int>? languages;
  final List<int>? interests;
  final List<int>? preferredGenders;
  final List<int>? relationGoals;
  final int? minAgePreference;
  final int? maxAgePreference;

  UpdateProfileRequest({
    this.profileBio,
    this.height,
    this.weight,
    this.smoke,
    this.drink,
    this.gym,
    this.musicGenres,
    this.educations,
    this.jobs,
    this.languages,
    this.interests,
    this.preferredGenders,
    this.relationGoals,
    this.minAgePreference,
    this.maxAgePreference,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (profileBio != null && profileBio!.isNotEmpty) json['profile_bio'] = profileBio;
    if (height != null) json['height'] = height;
    if (weight != null) json['weight'] = weight;
    if (smoke != null) json['smoke'] = smoke;
    if (drink != null) json['drink'] = drink;
    if (gym != null) json['gym'] = gym;
    if (musicGenres != null && musicGenres!.isNotEmpty) json['music_genres'] = musicGenres;
    if (educations != null && educations!.isNotEmpty) json['educations'] = educations;
    if (jobs != null && jobs!.isNotEmpty) json['jobs'] = jobs;
    if (languages != null && languages!.isNotEmpty) json['languages'] = languages;
    if (interests != null && interests!.isNotEmpty) json['interests'] = interests;
    if (preferredGenders != null && preferredGenders!.isNotEmpty) {
      json['preferred_genders'] = preferredGenders;
    }
    if (relationGoals != null && relationGoals!.isNotEmpty) json['relation_goals'] = relationGoals;
    if (minAgePreference != null) json['min_age_preference'] = minAgePreference;
    if (maxAgePreference != null) json['max_age_preference'] = maxAgePreference;
    return json;
  }
}

