/// User state response model
class UserStateResponse {
  final String userState;
  final int userId;
  final String email;
  final String? token;
  final String? tokenType;
  final bool? needsVerification;
  final ProfileCompletionStatus? profileCompletionStatus;

  UserStateResponse({
    required this.userState,
    required this.userId,
    required this.email,
    this.token,
    this.tokenType,
    this.needsVerification,
    this.profileCompletionStatus,
  });

  factory UserStateResponse.fromJson(Map<String, dynamic> json) {
    return UserStateResponse(
      userState: json['user_state'] as String,
      userId: json['user_id'] as int,
      email: json['email'] as String,
      token: json['token'] as String?,
      tokenType: json['token_type'] as String?,
      needsVerification: json['needs_verification'] as bool?,
      profileCompletionStatus: json['profile_completion_status'] != null
          ? ProfileCompletionStatus.fromJson(json['profile_completion_status'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Profile completion status model
class ProfileCompletionStatus {
  final bool isComplete;
  final List<String> missingFields;

  ProfileCompletionStatus({
    required this.isComplete,
    required this.missingFields,
  });

  factory ProfileCompletionStatus.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionStatus(
      isComplete: json['is_complete'] as bool? ?? false,
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

