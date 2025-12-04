import 'models.dart';

/// User profile model with full details
class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int? countryId;
  final String? country;
  final int? cityId;
  final String? city;
  final int? genderId;
  final String? gender;
  final String? birthDate;
  final String? profileBio;
  final int? height;
  final int? weight;
  final bool? smoke;
  final bool? drink;
  final bool? gym;
  final List<UserImage>? images;
  final List<int>? musicGenres;
  final List<int>? educations;
  final List<int>? jobs;
  final List<int>? languages;
  final List<int>? interests;
  final List<int>? preferredGenders;
  final List<int>? relationGoals;
  final int? minAgePreference;
  final int? maxAgePreference;
  final bool? isVerified;
  final bool? isPremium;
  final bool? isOnline;
  final bool? isPhoneVerified;
  final bool? isEmailVerified;
  final int? viewsCount;
  final DateTime? lastSeen;
  final Map<String, dynamic>? additionalData;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.countryId,
    this.country,
    this.cityId,
    this.city,
    this.genderId,
    this.gender,
    this.birthDate,
    this.profileBio,
    this.height,
    this.weight,
    this.smoke,
    this.drink,
    this.gym,
    this.images,
    this.musicGenres,
    this.educations,
    this.jobs,
    this.languages,
    this.interests,
    this.preferredGenders,
    this.relationGoals,
    this.minAgePreference,
    this.maxAgePreference,
    this.isVerified,
    this.isPremium,
    this.isOnline,
    this.isPhoneVerified,
    this.isEmailVerified,
    this.viewsCount,
    this.lastSeen,
    this.additionalData,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      countryId: json['country_id'] as int?,
      country: json['country'] as String?,
      cityId: json['city_id'] as int?,
      city: json['city'] as String?,
      genderId: json['gender_id'] as int?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] as String?,
      profileBio: json['profile_bio'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      smoke: json['smoke'] as bool?,
      drink: json['drink'] as bool?,
      gym: json['gym'] as bool?,
      images: json['images'] != null
          ? (json['images'] as List).map((i) => UserImage.fromJson(i as Map<String, dynamic>)).toList()
          : null,
      musicGenres: json['music_genres'] != null
          ? (json['music_genres'] as List).map((e) => e as int).toList()
          : null,
      educations: json['educations'] != null
          ? (json['educations'] as List).map((e) => e as int).toList()
          : null,
      jobs: json['jobs'] != null ? (json['jobs'] as List).map((e) => e as int).toList() : null,
      languages: json['languages'] != null
          ? (json['languages'] as List).map((e) => e as int).toList()
          : null,
      interests: json['interests'] != null
          ? (json['interests'] as List).map((e) => e as int).toList()
          : null,
      preferredGenders: json['preferred_genders'] != null
          ? (json['preferred_genders'] as List).map((e) => e as int).toList()
          : null,
      relationGoals: json['relation_goals'] != null
          ? (json['relation_goals'] as List).map((e) => e as int).toList()
          : null,
      minAgePreference: json['min_age_preference'] as int?,
      maxAgePreference: json['max_age_preference'] as int?,
      isVerified: json['is_verified'] as bool?,
      isPremium: json['is_premium'] as bool?,
      isOnline: json['is_online'] as bool?,
      isPhoneVerified: json['is_phone_verified'] as bool?,
      isEmailVerified: json['is_email_verified'] as bool?,
      viewsCount: json['views_count'] as int?,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen'] as String) : null,
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      if (countryId != null) 'country_id': countryId,
      if (country != null) 'country': country,
      if (cityId != null) 'city_id': cityId,
      if (city != null) 'city': city,
      if (genderId != null) 'gender_id': genderId,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate,
      if (profileBio != null) 'profile_bio': profileBio,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (smoke != null) 'smoke': smoke,
      if (drink != null) 'drink': drink,
      if (gym != null) 'gym': gym,
      if (images != null) 'images': images!.map((e) => e.toJson()).toList(),
      if (musicGenres != null) 'music_genres': musicGenres,
      if (educations != null) 'educations': educations,
      if (jobs != null) 'jobs': jobs,
      if (languages != null) 'languages': languages,
      if (interests != null) 'interests': interests,
      if (preferredGenders != null) 'preferred_genders': preferredGenders,
      if (relationGoals != null) 'relation_goals': relationGoals,
      if (minAgePreference != null) 'min_age_preference': minAgePreference,
      if (maxAgePreference != null) 'max_age_preference': maxAgePreference,
      if (isVerified != null) 'is_verified': isVerified,
      if (isPremium != null) 'is_premium': isPremium,
      if (isOnline != null) 'is_online': isOnline,
      if (isPhoneVerified != null) 'is_phone_verified': isPhoneVerified,
      if (isEmailVerified != null) 'is_email_verified': isEmailVerified,
      if (viewsCount != null) 'views_count': viewsCount,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
    };
  }
}

