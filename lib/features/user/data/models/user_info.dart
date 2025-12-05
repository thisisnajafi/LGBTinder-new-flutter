/// User info model
class UserInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
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
  final bool? showAdultContent;
  final Map<String, dynamic>? notificationPreferences;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
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
    this.showAdultContent,
    this.notificationPreferences,
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
    
    return UserInfo(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
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
      showAdultContent: json['show_adult_content'] == true || json['show_adult_content'] == 1,
      notificationPreferences: json['notification_preferences'] != null && json['notification_preferences'] is Map
          ? Map<String, dynamic>.from(json['notification_preferences'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
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
      if (showAdultContent != null) 'show_adult_content': showAdultContent,
      if (notificationPreferences != null) 'notification_preferences': notificationPreferences,
    };
  }
}

