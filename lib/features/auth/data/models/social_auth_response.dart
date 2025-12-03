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
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final profileCompletionStatus = data['profile_completion_status'] as Map<String, dynamic>?;

    bool profileCompleted = false;
    bool needsProfileCompletion = false;

    if (profileCompletionStatus != null) {
      final isComplete = profileCompletionStatus['is_complete'] as bool?;
      profileCompleted = isComplete ?? false;
      needsProfileCompletion = !profileCompleted;
    } else {
      final profileCompletedValue = data['profile_completed'];
      if (profileCompletedValue is bool) {
        profileCompleted = profileCompletedValue;
      } else if (profileCompletedValue is int) {
        profileCompleted = profileCompletedValue == 1;
      }
      needsProfileCompletion = data['needs_profile_completion'] as bool? ??
                              data['user_state'] == 'profile_completion_required' ||
                              !profileCompleted;
    }

    return SocialAuthResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      userId: data['user_id'] as int? ?? data['id'] as int?,
      email: data['email'] as String?,
      token: data['token'] as String?,
      tokenType: data['token_type'] as String?,
      profileCompleted: profileCompleted,
      needsProfileCompletion: needsProfileCompletion,
      userState: data['user_state'] as String?,
      firstName: data['first_name'] as String? ?? data['user']?['first_name'] as String?,
    );
  }
}
