/// Verify email response model
class VerifyEmailResponse {
  final int userId;
  final String email;
  final String? token;
  final String? tokenType;
  final bool profileCompletionRequired;
  final bool profileCompleted;

  VerifyEmailResponse({
    required this.userId,
    required this.email,
    this.token,
    this.tokenType,
    this.profileCompletionRequired = false,
    this.profileCompleted = false,
  });

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested user object structure
    Map<String, dynamic>? userData;
    int? userId;
    String? email;
    bool profileCompleted = false;
    
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      // Response has nested user object
      userData = json['user'] as Map<String, dynamic>;
      userId = userData['id'] as int? ?? 
               (userData['user_id'] as int?);
      email = userData['email'] as String?;
      // Check profile_completed field (can be bool or int 0/1)
      final profileCompletedValue = userData['profile_completed'];
      if (profileCompletedValue is bool) {
        profileCompleted = profileCompletedValue;
      } else if (profileCompletedValue is int) {
        profileCompleted = profileCompletedValue == 1;
      } else if (profileCompletedValue is String) {
        profileCompleted = profileCompletedValue.toLowerCase() == 'true' || profileCompletedValue == '1';
      }
    } else {
      // Response has flat structure
      userId = json['user_id'] as int? ?? (json['id'] as int?);
      email = json['email'] as String?;
      final profileCompletedValue = json['profile_completed'];
      if (profileCompletedValue is bool) {
        profileCompleted = profileCompletedValue;
      } else if (profileCompletedValue is int) {
        profileCompleted = profileCompletedValue == 1;
      } else if (profileCompletedValue is String) {
        profileCompleted = profileCompletedValue.toLowerCase() == 'true' || profileCompletedValue == '1';
      }
    }
    
    // Get token from data level or user level
    final token = json['token'] as String? ?? userData?['token'] as String?;
    final tokenType = json['token_type'] as String? ?? userData?['token_type'] as String?;
    
    // Determine if profile completion is required
    // If profile_completed is false, then completion is required
    final profileCompletionRequired = json['profile_completion_required'] as bool? ?? 
                                       (profileCompleted == false);

    // Validate required fields
    if (userId == null || userId == 0) {
      throw Exception('Invalid response: user ID is missing');
    }
    if (email == null || email.isEmpty) {
      throw Exception('Invalid response: email is missing');
    }

    return VerifyEmailResponse(
      userId: userId,
      email: email,
      token: token,
      tokenType: tokenType,
      profileCompletionRequired: profileCompletionRequired,
      profileCompleted: profileCompleted,
    );
  }
}

