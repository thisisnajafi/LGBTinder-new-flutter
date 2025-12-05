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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('UserInfo.fromJson: id is required but was null');
    }
    if (json['first_name'] == null) {
      throw FormatException('UserInfo.fromJson: first_name is required but was null');
    }
    if (json['last_name'] == null) {
      throw FormatException('UserInfo.fromJson: last_name is required but was null');
    }
    if (json['email'] == null) {
      throw FormatException('UserInfo.fromJson: email is required but was null');
    }
    
    return UserInfo(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      firstName: json['first_name'].toString(),
      lastName: json['last_name'].toString(),
      email: json['email'].toString(),
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

