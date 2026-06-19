import 'models.dart';
import '../../../../shared/models/match_reason.dart';

/// User profile model with full details
class UserProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
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
  /// Human-readable labels when API returns `interests: [{id, title}, ...]`.
  final List<String>? interestTitles;
  /// Human-readable labels when API returns `jobs: [{id, title}, ...]`.
  final List<String>? jobTitles;
  /// Human-readable labels when API returns `educations: [{id, title}, ...]`.
  final List<String>? educationTitles;
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
  final int? matchPercentage;
  final List<MatchReason> matchReasons;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  final String? locationSource;
  final Map<String, dynamic>? additionalData;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
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
    this.interestTitles,
    this.jobTitles,
    this.educationTitles,
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
    this.matchPercentage,
    this.matchReasons = const [],
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.locationSource,
    this.additionalData,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _labelFromMap(Map<String, dynamic> map) {
    final raw = map['title'] ?? map['name'] ?? map['label'];
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Parses API lists that may be `[1, 2]` or `[{id: 1, title: "..."}, ...]`.
  static ({List<int>? ids, List<String>? titles}) _parseRelationField(dynamic raw) {
    if (raw == null || raw is! List || raw.isEmpty) {
      return (ids: null, titles: null);
    }
    final ids = <int>[];
    final titles = <String>[];
    for (final entry in raw) {
      if (entry is int) {
        if (entry > 0) ids.add(entry);
      } else if (entry is num) {
        final id = entry.toInt();
        if (id > 0) ids.add(id);
      } else if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        final id = _parseInt(map['id']);
        final title = _labelFromMap(map);
        if (id != null && id > 0) ids.add(id);
        if (title != null) titles.add(title);
      } else {
        final parsed = int.tryParse(entry.toString());
        if (parsed != null && parsed > 0) ids.add(parsed);
      }
    }
    return (
      ids: ids.isEmpty ? null : ids,
      titles: titles.isEmpty ? null : titles,
    );
  }

  static String? _parseGenderLabel(Map<String, dynamic> json) {
    final detail = json['gender_detail'] ?? json['genderDetail'];
    if (detail is Map) {
      final label = _labelFromMap(Map<String, dynamic>.from(detail));
      if (label != null) return label;
    }
    final gender = json['gender'];
    if (gender is Map) {
      final label = _labelFromMap(Map<String, dynamic>.from(gender));
      if (label != null) return label;
    }
    if (gender is String) {
      final text = gender.trim();
      if (text.isNotEmpty && int.tryParse(text) == null) return text;
    }
    return null;
  }

  static List<String>? _titlesWithCacheFallback(
    List<String>? parsed,
    dynamic cached,
  ) {
    if (parsed != null && parsed.isNotEmpty) return parsed;
    if (cached is List && cached.isNotEmpty) {
      return cached.map((e) => e.toString()).where((t) => t.isNotEmpty).toList();
    }
    return parsed;
  }

  static int? _parseGenderId(Map<String, dynamic> json) {
    final fromField = _parseInt(json['gender_id']);
    if (fromField != null) return fromField;

    final detail = json['gender_detail'] ?? json['genderDetail'];
    if (detail is Map) {
      return _parseInt(Map<String, dynamic>.from(detail)['id']);
    }

    final gender = json['gender'];
    if (gender is int) return gender;
    if (gender is num) return gender.toInt();
    if (gender is String) return int.tryParse(gender);

    return null;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Get ID - use 0 as fallback (though this should typically be provided)
    int userId = 0;
    if (json['id'] != null) {
      userId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['user_id'] != null) {
      userId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    }
    
    // Get names - provide defaults if missing
    String firstName = json['first_name']?.toString() ?? 
                       json['firstName']?.toString() ?? 
                       'User';
    String lastName = json['last_name']?.toString() ?? 
                      json['lastName']?.toString() ?? 
                      '';
    
    // If we have a single 'name' field, split it
    if (firstName == 'User' && json['name'] != null) {
      final nameParts = json['name'].toString().trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }
    
    // Get email - provide default if missing
    String email = json['email']?.toString() ?? 
                   json['user_email']?.toString() ?? 
                   'user@unknown.com';
    
    return UserProfile(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: json['phone_number']?.toString() ??
          json['phoneNumber']?.toString(),
      countryId: json['country_id'] != null ? ((json['country_id'] is int) ? json['country_id'] as int : int.tryParse(json['country_id'].toString())) : null,
      country: json['country']?.toString(),
      cityId: json['city_id'] != null ? ((json['city_id'] is int) ? json['city_id'] as int : int.tryParse(json['city_id'].toString())) : null,
      city: json['city']?.toString(),
      genderId: _parseGenderId(json),
      gender: _parseGenderLabel(json),
      birthDate: json['birth_date']?.toString(),
      profileBio: json['profile_bio']?.toString(),
      height: json['height'] != null ? ((json['height'] is int) ? json['height'] as int : int.tryParse(json['height'].toString())) : null,
      weight: json['weight'] != null ? ((json['weight'] is int) ? json['weight'] as int : int.tryParse(json['weight'].toString())) : null,
      smoke: json['smoke'] == true || json['smoke'] == 1,
      drink: json['drink'] == true || json['drink'] == 1,
      gym: json['gym'] == true || json['gym'] == 1,
      images: json['images'] != null && json['images'] is List
          ? (json['images'] as List)
              .where((i) => i != null)
              .map((i) {
                try {
                  return UserImage.fromJson(i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i as Map));
                } catch (e) {
                  // Skip invalid image entries
                  return null;
                }
              })
              .whereType<UserImage>()
              .toList()
          : null,
      musicGenres: _parseRelationField(json['music_genres'] ?? json['musicGenres']).ids,
      educations: _parseRelationField(json['educations']).ids,
      educationTitles: _titlesWithCacheFallback(
        _parseRelationField(json['educations']).titles,
        json['education_titles'],
      ),
      jobs: _parseRelationField(json['jobs']).ids,
      jobTitles: _titlesWithCacheFallback(
        _parseRelationField(json['jobs']).titles,
        json['job_titles'],
      ),
      languages: _parseRelationField(json['languages']).ids,
      interests: _parseRelationField(json['interests']).ids,
      interestTitles: _titlesWithCacheFallback(
        _parseRelationField(json['interests']).titles,
        json['interest_titles'],
      ),
      preferredGenders: _parseRelationField(
        json['preferred_genders'] ?? json['preferredGenders'],
      ).ids,
      relationGoals: _parseRelationField(
        json['relation_goals'] ?? json['relationGoals'],
      ).ids,
      minAgePreference: json['min_age_preference'] != null ? ((json['min_age_preference'] is int) ? json['min_age_preference'] as int : int.tryParse(json['min_age_preference'].toString())) : null,
      maxAgePreference: json['max_age_preference'] != null ? ((json['max_age_preference'] is int) ? json['max_age_preference'] as int : int.tryParse(json['max_age_preference'].toString())) : null,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isPremium: json['is_premium'] == true || json['is_premium'] == 1,
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      isPhoneVerified: json['is_phone_verified'] == true || json['is_phone_verified'] == 1,
      isEmailVerified: json['is_email_verified'] == true || json['is_email_verified'] == 1,
      viewsCount: json['views_count'] != null ? ((json['views_count'] is int) ? json['views_count'] as int : int.tryParse(json['views_count'].toString())) : null,
      lastSeen: json['last_seen'] != null ? DateTime.tryParse(json['last_seen'].toString()) : null,
      matchPercentage: json['match_percentage'] != null
          ? ((json['match_percentage'] is int)
              ? json['match_percentage'] as int
              : int.tryParse(json['match_percentage'].toString()))
          : null,
      matchReasons: json['match_reasons'] != null && json['match_reasons'] is List
          ? (json['match_reasons'] as List)
              .whereType<Map>()
              .map((e) => MatchReason.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      latitude: _parseDouble(json['latitude'] ?? json['lats']),
      longitude: _parseDouble(json['longitude'] ?? json['longs']),
      locationUpdatedAt: json['location_updated_at'] != null
          ? DateTime.tryParse(json['location_updated_at'].toString())
          : null,
      locationSource: json['location_source']?.toString(),
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
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
      if (interestTitles != null) 'interest_titles': interestTitles,
      if (jobTitles != null) 'job_titles': jobTitles,
      if (educationTitles != null) 'education_titles': educationTitles,
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
      if (matchPercentage != null) 'match_percentage': matchPercentage,
      if (matchReasons.isNotEmpty)
        'match_reasons': matchReasons.map((e) => e.toJson()).toList(),
    };
  }
}

