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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('UserData.fromJson: id is required but was null');
    }
    if (json['email'] == null) {
      throw FormatException('UserData.fromJson: email is required but was null');
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
      throw FormatException('UserData.fromJson: first_name (or name) is required but was null or empty');
    }
    
    return UserData(
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

