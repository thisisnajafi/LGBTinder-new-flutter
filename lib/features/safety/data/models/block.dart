/// Blocked user model
class BlockedUser {
  final int id;
  final int blockedUserId;
  final String firstName;
  final String? lastName;
  final String? primaryImageUrl;
  final String? reason;
  final DateTime blockedAt;

  BlockedUser({
    required this.id,
    required this.blockedUserId,
    required this.firstName,
    this.lastName,
    this.primaryImageUrl,
    this.reason,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as int? ?? json['block_id'] as int? ?? 0,
      blockedUserId: json['blocked_user_id'] as int? ?? json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      primaryImageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      reason: json['reason'] as String?,
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocked_user_id': blockedUserId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      if (reason != null) 'reason': reason,
      'blocked_at': blockedAt.toIso8601String(),
    };
  }
}

/// Block user request
class BlockUserRequest {
  final int blockedUserId;
  final String? reason;

  BlockUserRequest({
    required this.blockedUserId,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'blocked_user_id': blockedUserId,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }
}
