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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('AuthUser.fromJson: id is required but was null');
    }
    if (json['email'] == null) {
      throw FormatException('AuthUser.fromJson: email is required but was null');
    }
    
    // Handle both formats: 'name' (single field) or 'first_name'/'last_name' (separate fields)
    String firstName;
    String lastName;

    if (json['name'] != null) {
      // Backend returns 'name' as a single field, split it
      final nameParts = json['name'].toString().trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else {
      // Backend returns 'first_name' and 'last_name' separately
      firstName = json['first_name']?.toString() ?? '';
      lastName = json['last_name']?.toString() ?? '';
    }
    
    // If first name is still empty, throw error
    if (firstName.isEmpty) {
      throw FormatException('AuthUser.fromJson: first_name (or name) is required but was null or empty');
    }

    return AuthUser(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      firstName: firstName,
      lastName: lastName,
      email: json['email'].toString(),
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      gender: json['gender']?.toString(),
      birthDate: json['birth_date']?.toString(),
      profileBio: json['profile_bio']?.toString(),
      height: json['height'] != null ? ((json['height'] is int) ? json['height'] as int : int.tryParse(json['height'].toString())) : null,
      weight: json['weight'] != null ? ((json['weight'] is int) ? json['weight'] as int : int.tryParse(json['weight'].toString())) : null,
      smoke: json['smoke'] == true || json['smoke'] == 1 || json['smoke'] == '1',
      drink: json['drink'] == true || json['drink'] == 1 || json['drink'] == '1',
      gym: json['gym'] == true || json['gym'] == 1 || json['gym'] == '1',
      images: json['images'] != null && json['images'] is List ? json['images'] as List<dynamic> : null,
      avatarUrl: json['avatar_url']?.toString(),
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
