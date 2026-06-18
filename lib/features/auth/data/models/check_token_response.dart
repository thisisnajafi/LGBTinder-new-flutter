import 'login_response.dart';

/// Response from GET /auth/check-token (app bootstrap).
class CheckTokenResponse {
  final bool isComplete;
  final bool needsProfileCompletion;
  final String userState;
  final UserData? user;

  const CheckTokenResponse({
    required this.isComplete,
    required this.needsProfileCompletion,
    required this.userState,
    this.user,
  });

  factory CheckTokenResponse.fromJson(Map<String, dynamic> json) {
    final profileStatus =
        json['profile_completion_status'] as Map<String, dynamic>?;

    bool isComplete = json['is_complete'] == true || json['is_complete'] == 1;
    if (!isComplete && profileStatus != null) {
      isComplete = profileStatus['is_complete'] == true ||
          profileStatus['is_complete'] == 1;
    }
    if (!isComplete) {
      isComplete = json['profile_completed'] == true ||
          json['profile_completed'] == 1;
    }

    final userState = json['user_state']?.toString() ??
        (isComplete ? 'ready_for_app' : 'profile_completion_required');

    final needsProfileCompletion = json['needs_profile_completion'] == true ||
        json['needs_profile_completion'] == 1 ||
        !isComplete;

    UserData? user;
    final userJson = json['user'];
    if (userJson is Map<String, dynamic>) {
      user = UserData.fromJson(userJson);
    }

    return CheckTokenResponse(
      isComplete: isComplete,
      needsProfileCompletion: needsProfileCompletion,
      userState: userState,
      user: user,
    );
  }
}
