import '../../features/auth/data/models/login_response.dart';

/// Persisted user session (secure storage) for offline app state and guards.
class StoredUserSession {
  final UserData user;
  final bool profileCompleted;
  final String? userState;

  const StoredUserSession({
    required this.user,
    this.profileCompleted = false,
    this.userState,
  });

  factory StoredUserSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw const FormatException('Missing user in stored session');
    }
    return StoredUserSession(
      user: UserData.fromJson(userJson),
      profileCompleted: json['profile_completed'] == true,
      userState: json['user_state'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'profile_completed': profileCompleted,
        if (userState != null) 'user_state': userState,
      };
}
