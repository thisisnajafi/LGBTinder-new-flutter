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
    return UserInfo(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      country: json['country'] as String?,
      city: json['city'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] as String?,
      profileBio: json['profile_bio'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      smoke: json['smoke'] as bool?,
      drink: json['drink'] as bool?,
      gym: json['gym'] as bool?,
      images: json['images'] as List<dynamic>?,
      showAdultContent: json['show_adult_content'] as bool?,
      notificationPreferences: json['notification_preferences'] as Map<String, dynamic>?,
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

