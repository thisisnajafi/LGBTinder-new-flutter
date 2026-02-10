/// User info model (GET /api/user — avatar, preferences, plan, etc.)
class UserInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? gender;
  final String? birthDate;
  final String? profileBio;
  final int? height;
  final int? weight;
  final bool? smoke;
  final bool? drink;
  final bool? gym;
  final List<dynamic>? images;
  final String? avatarUrl;
  final bool? showAdultContent;
  final Map<String, dynamic>? notificationPreferences;
  /// Jobs from API: [{ id, title }, ...]
  final List<Map<String, dynamic>>? jobs;
  /// Educations from API: [{ id, title }, ...]
  final List<Map<String, dynamic>>? educations;
  /// Subscription/plan info from API (if present)
  final Map<String, dynamic>? subscription;
  final Map<String, dynamic>? plan;
  /// Raw preferences / extra fields from API for caching
  final Map<String, dynamic>? preferences;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.country,
    this.city,
    this.gender,
    this.birthDate,
    this.profileBio,
    this.height,
    this.weight,
    this.smoke,
    this.drink,
    this.gym,
    this.images,
    this.avatarUrl,
    this.showAdultContent,
    this.notificationPreferences,
    this.jobs,
    this.educations,
    this.subscription,
    this.plan,
    this.preferences,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // Get ID - use 0 as fallback
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
    
    List<Map<String, dynamic>>? jobs;
    if (json['jobs'] != null && json['jobs'] is List) {
      jobs = (json['jobs'] as List)
          .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{})
          .toList();
    }
    List<Map<String, dynamic>>? educations;
    if (json['educations'] != null && json['educations'] is List) {
      educations = (json['educations'] as List)
          .map((e) => e is Map ? Map<String, dynamic>.from(e as Map) : <String, dynamic>{})
          .toList();
    }

    return UserInfo(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      fullName: json['full_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      gender: json['gender']?.toString(),
      birthDate: json['birth_date']?.toString(),
      profileBio: json['profile_bio']?.toString(),
      height: json['height'] != null ? ((json['height'] is int) ? json['height'] as int : int.tryParse(json['height'].toString())) : null,
      weight: json['weight'] != null ? ((json['weight'] is int) ? json['weight'] as int : int.tryParse(json['weight'].toString())) : null,
      smoke: json['smoke'] == true || json['smoke'] == 1,
      drink: json['drink'] == true || json['drink'] == 1,
      gym: json['gym'] == true || json['gym'] == 1,
      images: json['images'] != null && json['images'] is List ? json['images'] as List<dynamic> : null,
      avatarUrl: json['avatar_url']?.toString(),
      showAdultContent: json['show_adult_content'] == true || json['show_adult_content'] == 1,
      notificationPreferences: json['notification_preferences'] != null && json['notification_preferences'] is Map
          ? Map<String, dynamic>.from(json['notification_preferences'] as Map)
          : null,
      jobs: jobs,
      educations: educations,
      subscription: json['subscription'] != null && json['subscription'] is Map
          ? Map<String, dynamic>.from(json['subscription'] as Map)
          : null,
      plan: json['plan'] != null && json['plan'] is Map
          ? Map<String, dynamic>.from(json['plan'] as Map)
          : null,
      preferences: json['preferences'] != null && json['preferences'] is Map
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birth_date': birthDate,
      if (profileBio != null) 'profile_bio': profileBio,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (smoke != null) 'smoke': smoke,
      if (drink != null) 'drink': drink,
      if (gym != null) 'gym': gym,
      if (images != null) 'images': images,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (showAdultContent != null) 'show_adult_content': showAdultContent,
      if (notificationPreferences != null) 'notification_preferences': notificationPreferences,
      if (jobs != null) 'jobs': jobs,
      if (educations != null) 'educations': educations,
      if (subscription != null) 'subscription': subscription,
      if (plan != null) 'plan': plan,
      if (preferences != null) 'preferences': preferences,
    };
  }

  /// Primary avatar URL: avatar_url from API or first image URL from images list
  String? get primaryAvatarUrl {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) return avatarUrl;
    if (images != null && images!.isNotEmpty) {
      final first = images!.first;
      if (first is String) return first;
      if (first is Map && first['image_url'] != null) return first['image_url'] as String?;
    }
    return null;
  }
}

