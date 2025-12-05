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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('UserProfile.fromJson: id is required but was null');
    }
    if (json['first_name'] == null) {
      throw FormatException('UserProfile.fromJson: first_name is required but was null');
    }
    if (json['last_name'] == null) {
      throw FormatException('UserProfile.fromJson: last_name is required but was null');
    }
    if (json['email'] == null) {
      throw FormatException('UserProfile.fromJson: email is required but was null');
    }
    
    return UserProfile(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      firstName: json['first_name'].toString(),
      lastName: json['last_name'].toString(),
      email: json['email'].toString(),
      countryId: json['country_id'] != null ? ((json['country_id'] is int) ? json['country_id'] as int : int.tryParse(json['country_id'].toString())) : null,
      country: json['country']?.toString(),
      cityId: json['city_id'] != null ? ((json['city_id'] is int) ? json['city_id'] as int : int.tryParse(json['city_id'].toString())) : null,
      city: json['city']?.toString(),
      genderId: json['gender_id'] != null ? ((json['gender_id'] is int) ? json['gender_id'] as int : int.tryParse(json['gender_id'].toString())) : null,
      gender: json['gender']?.toString(),
      birthDate: json['birth_date']?.toString(),
      profileBio: json['profile_bio']?.toString(),
      height: json['height'] != null ? ((json['height'] is int) ? json['height'] as int : int.tryParse(json['height'].toString())) : null,
      weight: json['weight'] != null ? ((json['weight'] is int) ? json['weight'] as int : int.tryParse(json['weight'].toString())) : null,
      smoke: json['smoke'] == true || json['smoke'] == 1,
      drink: json['drink'] == true || json['drink'] == 1,
      gym: json['gym'] == true || json['gym'] == 1,
      images: json['images'] != null && json['images'] is List
          ? (json['images'] as List).map((i) => UserImage.fromJson(i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i as Map))).toList()
          : null,
      musicGenres: json['music_genres'] != null && json['music_genres'] is List
          ? (json['music_genres'] as List).map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      educations: json['educations'] != null && json['educations'] is List
          ? (json['educations'] as List).map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      jobs: json['jobs'] != null && json['jobs'] is List
          ? (json['jobs'] as List).map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      languages: json['languages'] != null && json['languages'] is List
          ? (json['languages'] as List).map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      interests: json['interests'] != null && json['interests'] is List
          ? (json['interests'] as List).map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      preferredGenders: json['preferred_genders'] != null && json['preferred_genders'] is List
          ? (json['preferred_genders'] as List).map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      relationGoals: json['relation_goals'] != null && json['relation_goals'] is List
          ? (json['relation_goals'] as List).map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0).toList()
          : null,
      minAgePreference: json['min_age_preference'] != null ? ((json['min_age_preference'] is int) ? json['min_age_preference'] as int : int.tryParse(json['min_age_preference'].toString())) : null,
      maxAgePreference: json['max_age_preference'] != null ? ((json['max_age_preference'] is int) ? json['max_age_preference'] as int : int.tryParse(json['max_age_preference'].toString())) : null,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isPremium: json['is_premium'] == true || json['is_premium'] == 1,
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      isPhoneVerified: json['is_phone_verified'] == true || json['is_phone_verified'] == 1,
      isEmailVerified: json['is_email_verified'] == true || json['is_email_verified'] == 1,
      viewsCount: json['views_count'] != null ? ((json['views_count'] is int) ? json['views_count'] as int : int.tryParse(json['views_count'].toString())) : null,
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'].toString()) : null,
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

