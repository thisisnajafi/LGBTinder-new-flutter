/// Auth User model - represents authenticated user data
class AuthUser {
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
  final String? avatarUrl;

  AuthUser({
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
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    // Handle both formats: 'name' (single field) or 'first_name'/'last_name' (separate fields)
    String firstName;
    String lastName;

    if (json['name'] != null) {
      // Backend returns 'name' as a single field, split it
      final nameParts = (json['name'] as String).trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else {
      // Backend returns 'first_name' and 'last_name' separately
      firstName = json['first_name'] as String? ?? '';
      lastName = json['last_name'] as String? ?? '';
    }

    return AuthUser(
      id: json['id'] as int,
      firstName: firstName,
      lastName: lastName,
      email: json['email'] as String,
      country: json['country'] as String?,
      city: json['city'] as String?,
      gender: json['gender']?.toString(), // Convert to string if it's an integer
      birthDate: json['birth_date'] as String?,
      profileBio: json['profile_bio'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      smoke: json['smoke'] is bool ? json['smoke'] as bool? : (json['smoke'] == 1 || json['smoke'] == '1'), // Handle both bool and int (0/1)
      drink: json['drink'] is bool ? json['drink'] as bool? : (json['drink'] == 1 || json['drink'] == '1'), // Handle both bool and int (0/1)
      gym: json['gym'] is bool ? json['gym'] as bool? : (json['gym'] == 1 || json['gym'] == '1'), // Handle both bool and int (0/1)
      images: json['images'] as List<dynamic>?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'name': '$firstName $lastName'.trim(),
      'email': email,
      'country': country,
      'city': city,
      'gender': gender,
      'birth_date': birthDate,
      'profile_bio': profileBio,
      'height': height,
      'weight': weight,
      'smoke': smoke,
      'drink': drink,
      'gym': gym,
      'images': images,
      'avatar_url': avatarUrl,
    };
  }
}
