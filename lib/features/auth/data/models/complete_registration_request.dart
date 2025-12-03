/// Complete profile registration request model
class CompleteRegistrationRequest {
  final String deviceName;
  final String phoneNumber;
  final int countryId;
  final int cityId;
  final int gender;
  final String birthDate;
  final int minAgePreference;
  final int maxAgePreference;
  final String profileBio;
  final int height;
  final int weight;
  final bool smoke;
  final bool drink;
  final bool gym;
  final List<int> musicGenres;
  final List<int> educations;
  final List<int> jobs;
  final List<int> languages;
  final List<int> interests;
  final List<int> preferredGenders;
  final List<int> relationGoals;

  CompleteRegistrationRequest({
    required this.deviceName,
    required this.phoneNumber,
    required this.countryId,
    required this.cityId,
    required this.gender,
    required this.birthDate,
    required this.minAgePreference,
    required this.maxAgePreference,
    required this.profileBio,
    required this.height,
    required this.weight,
    required this.smoke,
    required this.drink,
    required this.gym,
    required this.musicGenres,
    required this.educations,
    required this.jobs,
    required this.languages,
    required this.interests,
    required this.preferredGenders,
    required this.relationGoals,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_name': deviceName,
      'phone_number': phoneNumber,
      'country_id': countryId,
      'city_id': cityId,
      'gender': gender,
      'birth_date': birthDate,
      'min_age_preference': minAgePreference,
      'max_age_preference': maxAgePreference,
      'profile_bio': profileBio,
      'height': height,
      'weight': weight,
      'smoke': smoke,
      'drink': drink,
      'gym': gym,
      'music_genres': musicGenres,
      'educations': educations,
      'jobs': jobs,
      'languages': languages,
      'interests': interests,
      'preferred_genders': preferredGenders,
      'relation_goals': relationGoals,
    };
  }
}

