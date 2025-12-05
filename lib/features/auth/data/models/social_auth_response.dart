/// Social authentication response model
class SocialAuthResponse {
  final bool status;
  final String message;
  final int? userId;
  final String? email;
  final String? token;
  final String? tokenType;
  final bool profileCompleted;
  final bool needsProfileCompletion;
  final String? userState;
  final String? firstName;

  SocialAuthResponse({
    required this.status,
    required this.message,
    this.userId,
    this.email,
    this.token,
    this.tokenType,
    this.profileCompleted = false,
    this.needsProfileCompletion = false,
    this.userState,
    this.firstName,
  });

  factory SocialAuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] != null && json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final profileCompletionStatus = data['profile_completion_status'] != null && data['profile_completion_status'] is Map
        ? Map<String, dynamic>.from(data['profile_completion_status'] as Map)
        : null;

    bool profileCompleted = false;
    bool needsProfileCompletion = false;

    if (profileCompletionStatus != null) {
      profileCompleted = profileCompletionStatus['is_complete'] == true || profileCompletionStatus['is_complete'] == 1;
      needsProfileCompletion = !profileCompleted;
    } else {
      profileCompleted = data['profile_completed'] == true || data['profile_completed'] == 1;
      needsProfileCompletion = data['needs_profile_completion'] == true || 
                              data['needs_profile_completion'] == 1 ||
                              data['user_state']?.toString() == 'profile_completion_required' ||
                              !profileCompleted;
    }

    return SocialAuthResponse(
      status: json['status'] == true || json['status'] == 1 || json['status'] == 'true',
      message: json['message']?.toString() ?? '',
      userId: data['user_id'] != null 
          ? ((data['user_id'] is int) ? data['user_id'] as int : int.tryParse(data['user_id'].toString()))
          : (data['id'] != null ? ((data['id'] is int) ? data['id'] as int : int.tryParse(data['id'].toString())) : null),
      email: data['email']?.toString(),
      token: data['token']?.toString(),
      tokenType: data['token_type']?.toString(),
      profileCompleted: profileCompleted,
      needsProfileCompletion: needsProfileCompletion,
      userState: data['user_state']?.toString(),
      firstName: data['first_name']?.toString() ?? (data['user'] != null && data['user'] is Map ? (data['user'] as Map)['first_name']?.toString() : null),
    );
  }
}
