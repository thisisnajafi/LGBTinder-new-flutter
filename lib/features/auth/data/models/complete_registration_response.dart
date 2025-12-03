import 'login_response.dart';

/// Complete registration response model
class CompleteRegistrationResponse {
  final UserData? user;
  final String? token;
  final String? tokenType;
  final String? onesignalPlayerId;
  final bool profileCompleted;
  final bool needsProfileCompletion;
  final String? userState;

  CompleteRegistrationResponse({
    this.user,
    this.token,
    this.tokenType,
    this.onesignalPlayerId,
    this.profileCompleted = false,
    this.needsProfileCompletion = false,
    this.userState,
  });

  factory CompleteRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return CompleteRegistrationResponse(
      user: json['user'] != null ? UserData.fromJson(json['user'] as Map<String, dynamic>) : null,
      token: json['token'] as String?,
      tokenType: json['token_type'] as String?,
      onesignalPlayerId: json['onesignal_player_id'] as String?,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      needsProfileCompletion: json['needs_profile_completion'] as bool? ?? false,
      userState: json['user_state'] as String?,
    );
  }
}

