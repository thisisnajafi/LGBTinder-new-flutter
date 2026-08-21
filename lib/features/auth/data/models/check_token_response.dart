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

    final wizardCompleted = _flag(json['profile_completed']) ||
        _flag(profileStatus?['profile_completed']);

    var isComplete = _flag(json['is_complete']) ||
        _flag(profileStatus?['is_complete']) ||
        wizardCompleted;

    var userState = json['user_state']?.toString();
    if (userState == null || userState.isEmpty) {
      userState =
          isComplete ? 'ready_for_app' : 'profile_completion_required';
    }

    // The wizard-done column wins over the strict field checklist. A
    // completed user must not be sent through onboarding again after a
    // cache wipe, even if photos/relations fail isProfileComplete().
    if (wizardCompleted && userState != 'email_verification_required') {
      isComplete = true;
      userState = 'ready_for_app';
    } else if (userState == 'ready_for_app') {
      isComplete = true;
    }

    final needsProfileCompletion = userState == 'profile_completion_required' ||
        (!isComplete &&
            (_flag(json['needs_profile_completion']) ||
                _flag(profileStatus?['needs_profile_completion'])));

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

  static bool _flag(dynamic value) =>
      value == true || value == 1 || value == '1';
}
