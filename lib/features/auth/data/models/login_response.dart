/// Login response model
class LoginResponse {
  final UserData? user;
  final String? token;
  final String? tokenType;
  final String? onesignalPlayerId;
  final bool profileCompleted;
  final bool needsProfileCompletion;
  final String? userState;
  final String? firstName; // first_name from top level of data

  LoginResponse({
    this.user,
    this.token,
    this.tokenType,
    this.onesignalPlayerId,
    this.profileCompleted = false,
    this.needsProfileCompletion = false,
    this.userState,
    this.firstName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Check profile_completion_status structure
    final profileCompletionStatus = json['profile_completion_status'] as Map<String, dynamic>?;
    bool profileCompleted = false;
    bool needsProfileCompletion = false;
    
    if (profileCompletionStatus != null) {
      // Use profile_completion_status.is_complete if available
      final isComplete = profileCompletionStatus['is_complete'] as bool?;
      profileCompleted = isComplete ?? false;
      needsProfileCompletion = !profileCompleted;
    } else {
      // Fallback to direct fields
      final profileCompletedValue = json['profile_completed'];
      if (profileCompletedValue is bool) {
        profileCompleted = profileCompletedValue;
      } else if (profileCompletedValue is int) {
        profileCompleted = profileCompletedValue == 1;
      }
      needsProfileCompletion = json['needs_profile_completion'] as bool? ?? 
                                json['user_state'] == 'profile_completion_required' ||
                                !profileCompleted;
    }
    
    // Determine user state
    final userState = json['user_state'] as String?;
    if (userState == null && needsProfileCompletion) {
      // Infer user state from profile completion status
      needsProfileCompletion = true;
    }

    return LoginResponse(
      user: json['user'] != null ? UserData.fromJson(json['user'] as Map<String, dynamic>) : null,
      token: json['token'] as String?,
      tokenType: json['token_type'] as String?,
      onesignalPlayerId: json['onesignal_player_id'] as String?,
      profileCompleted: profileCompleted,
      needsProfileCompletion: needsProfileCompletion,
      userState: userState,
      firstName: json['first_name'] as String? ?? json['user']?['first_name'] as String?,
    );
  }
}

/// User data model (simplified for login response)
class UserData {
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

  UserData({
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

  factory UserData.fromJson(Map<String, dynamic> json) {
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
    
    return UserData(
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
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }
}

