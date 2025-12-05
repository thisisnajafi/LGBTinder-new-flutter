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
    // Validate required fields
    if (json['user_state'] == null) {
      throw FormatException('UserStateResponse.fromJson: user_state is required but was null');
    }
    if (json['user_id'] == null) {
      throw FormatException('UserStateResponse.fromJson: user_id is required but was null');
    }
    if (json['email'] == null) {
      throw FormatException('UserStateResponse.fromJson: email is required but was null');
    }
    
    return UserStateResponse(
      userState: json['user_state'].toString(),
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      email: json['email'].toString(),
      token: json['token']?.toString(),
      tokenType: json['token_type']?.toString(),
      needsVerification: json['needs_verification'] == true || json['needs_verification'] == 1,
      profileCompletionStatus: json['profile_completion_status'] != null && json['profile_completion_status'] is Map
          ? ProfileCompletionStatus.fromJson(Map<String, dynamic>.from(json['profile_completion_status'] as Map))
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
      isComplete: json['is_complete'] == true || json['is_complete'] == 1,
      missingFields: json['missing_fields'] != null && json['missing_fields'] is List
          ? (json['missing_fields'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }
}

