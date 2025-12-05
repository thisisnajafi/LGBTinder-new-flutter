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
      user: json['user'] != null && json['user'] is Map
          ? UserData.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      token: json['token']?.toString(),
      tokenType: json['token_type']?.toString(),
      onesignalPlayerId: json['onesignal_player_id']?.toString(),
      profileCompleted: json['profile_completed'] == true || json['profile_completed'] == 1,
      needsProfileCompletion: json['needs_profile_completion'] == true || json['needs_profile_completion'] == 1,
      userState: json['user_state']?.toString(),
    );
  }
}

