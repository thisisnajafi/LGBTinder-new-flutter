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
  final String? lastName;
  final bool isNewUser;
  final bool accountLinked;

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
    this.lastName,
    this.isNewUser = false,
    this.accountLinked = false,
  });

  factory SocialAuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] != null && json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final userMap = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : null;

    final profileCompletionStatus =
        data['profile_completion_status'] is Map
            ? Map<String, dynamic>.from(
                data['profile_completion_status'] as Map,
              )
            : null;

    bool profileCompleted = false;
    bool needsProfileCompletion = false;

    if (profileCompletionStatus != null) {
      profileCompleted =
          profileCompletionStatus['is_complete'] == true ||
          profileCompletionStatus['is_complete'] == 1;
      needsProfileCompletion = !profileCompleted;
    } else {
      profileCompleted = data['profile_completed'] == true ||
          data['profile_completed'] == 1 ||
          data['profile_complete'] == true ||
          data['profile_complete'] == 1 ||
          userMap?['profile_completed'] == true ||
          userMap?['profile_complete'] == true;
      needsProfileCompletion = data['needs_profile_completion'] == true ||
          data['needs_profile_completion'] == 1 ||
          data['user_state']?.toString() == 'profile_completion_required' ||
          !profileCompleted;
    }

    final userState = data['user_state']?.toString() ??
        (profileCompleted ? 'ready_for_app' : 'profile_completion_required');

    final userId = _parseInt(data['user_id']) ??
        _parseInt(userMap?['id']) ??
        _parseInt(data['id']);

    final email = data['email']?.toString() ?? userMap?['email']?.toString();

    return SocialAuthResponse(
      status: json['status'] == true ||
          json['status'] == 1 ||
          json['status'] == 'true' ||
          json['status'] == 'success',
      message: json['message']?.toString() ?? '',
      userId: userId,
      email: email,
      token: data['token']?.toString(),
      tokenType: data['token_type']?.toString(),
      profileCompleted: profileCompleted,
      needsProfileCompletion: needsProfileCompletion,
      userState: userState,
      firstName: data['first_name']?.toString() ??
          userMap?['first_name']?.toString(),
      lastName: data['last_name']?.toString() ??
          userMap?['last_name']?.toString(),
      isNewUser: data['is_new_user'] == true || data['is_new_user'] == 1,
      accountLinked:
          data['account_linked'] == true || data['account_linked'] == 1,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
