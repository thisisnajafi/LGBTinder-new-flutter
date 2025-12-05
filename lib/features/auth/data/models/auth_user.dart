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
    // Get ID - use 0 as fallback
    int userId = 0;
    if (json['id'] != null) {
      userId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['user_id'] != null) {
      userId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    }
    
    // Handle both formats: 'name' (single field) or 'first_name'/'last_name' (separate fields)
    String firstName = 'User';
    String lastName = '';

    if (json['name'] != null) {
      // Backend returns 'name' as a single field, split it
      final nameParts = json['name'].toString().trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else if (json['first_name'] != null) {
      // Backend returns 'first_name' and 'last_name' separately
      firstName = json['first_name'].toString();
      lastName = json['last_name']?.toString() ?? '';
    }
    
    // Get email - provide default if missing
    String email = json['email']?.toString() ?? 
                   json['user_email']?.toString() ?? 
                   'user@unknown.com';

    return AuthUser(
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
