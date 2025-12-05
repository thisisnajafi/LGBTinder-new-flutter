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
    // Validate required fields
    if (json['first_name'] == null) {
      throw FormatException('BlockedUser.fromJson: first_name is required but was null');
    }
    
    // Get ID from multiple possible fields
    int blockId = 0;
    if (json['id'] != null) {
      blockId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['block_id'] != null) {
      blockId = (json['block_id'] is int) ? json['block_id'] as int : int.tryParse(json['block_id'].toString()) ?? 0;
    }
    
    // Get user ID - validate it exists
    int blockedUserId;
    if (json['blocked_user_id'] != null) {
      blockedUserId = (json['blocked_user_id'] is int) ? json['blocked_user_id'] as int : int.parse(json['blocked_user_id'].toString());
    } else if (json['user_id'] != null) {
      blockedUserId = (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString());
    } else {
      throw FormatException('BlockedUser.fromJson: blocked_user_id (or user_id) is required but was null');
    }
    
    return BlockedUser(
      id: blockId,
      blockedUserId: blockedUserId,
      firstName: json['first_name'].toString(),
      lastName: json['last_name']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
      reason: json['reason']?.toString(),
      blockedAt: json['blocked_at'] != null
          ? (DateTime.tryParse(json['blocked_at'].toString()) ?? DateTime.now())
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
