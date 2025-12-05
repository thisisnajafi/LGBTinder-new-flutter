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
    
    if (json['user'] != null && json['user'] is Map) {
      // Response has nested user object
      userData = Map<String, dynamic>.from(json['user'] as Map);
      userId = userData['id'] != null 
          ? ((userData['id'] is int) ? userData['id'] as int : int.tryParse(userData['id'].toString()))
          : (userData['user_id'] != null ? ((userData['user_id'] is int) ? userData['user_id'] as int : int.tryParse(userData['user_id'].toString())) : null);
      email = userData['email']?.toString();
      // Check profile_completed field (can be bool or int 0/1)
      profileCompleted = userData['profile_completed'] == true || userData['profile_completed'] == 1 || userData['profile_completed'] == '1';
    } else {
      // Response has flat structure
      userId = json['user_id'] != null 
          ? ((json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()))
          : (json['id'] != null ? ((json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString())) : null);
      email = json['email']?.toString();
      profileCompleted = json['profile_completed'] == true || json['profile_completed'] == 1 || json['profile_completed'] == '1';
    }
    
    // Get token from data level or user level
    final token = json['token']?.toString() ?? userData?['token']?.toString();
    final tokenType = json['token_type']?.toString() ?? userData?['token_type']?.toString();
    
    // Determine if profile completion is required
    // If profile_completed is false, then completion is required
    final profileCompletionRequired = json['profile_completion_required'] == true || 
                                       json['profile_completion_required'] == 1 ||
                                       !profileCompleted;

    // Validate required fields
    if (userId == null || userId == 0) {
      throw FormatException('VerifyEmailResponse.fromJson: user_id is required but was null or 0');
    }
    if (email == null || email.isEmpty) {
      throw FormatException('VerifyEmailResponse.fromJson: email is required but was null or empty');
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

