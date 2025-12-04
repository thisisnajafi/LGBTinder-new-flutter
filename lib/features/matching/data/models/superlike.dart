// Re-export Match for convenience
export 'match.dart';

import 'match.dart';

/// Superlike model
class Superlike {
  final int id;
  final int superlikedUserId;
  final String firstName;
  final String? lastName;
  final String? primaryImageUrl;
  final DateTime superlikedAt;
  final bool? isMatch;
  final bool? hasResponded;
  final int? remainingSuperlikes;

  Superlike({
    required this.id,
    required this.superlikedUserId,
    required this.firstName,
    this.lastName,
    this.primaryImageUrl,
    required this.superlikedAt,
    this.isMatch = false,
    this.hasResponded = false,
    this.remainingSuperlikes,
  });

  factory Superlike.fromJson(Map<String, dynamic> json) {
    return Superlike(
      id: json['id'] as int? ?? json['superlike_id'] as int? ?? 0,
      superlikedUserId: json['superliked_user_id'] as int? ?? json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      primaryImageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      superlikedAt: json['superliked_at'] != null
          ? DateTime.parse(json['superliked_at'] as String)
          : DateTime.now(),
      isMatch: json['is_match'] as bool? ?? false,
      hasResponded: json['has_responded'] as bool? ?? false,
      remainingSuperlikes: json['remaining_superlikes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'superliked_user_id': superlikedUserId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      'superliked_at': superlikedAt.toIso8601String(),
      'is_match': isMatch,
      'has_responded': hasResponded,
      if (remainingSuperlikes != null) 'remaining_superlikes': remainingSuperlikes,
    };
  }
}

/// Superlike action request
class SuperlikeActionRequest {
  final int superlikedUserId;

  SuperlikeActionRequest({required this.superlikedUserId});

  Map<String, dynamic> toJson() {
    return {'superliked_user_id': superlikedUserId};
  }
}

/// Superlike response (for match detection)
class SuperlikeResponse {
  final bool isMatch;
  final Match? match;
  final String? message;
  final int? remainingSuperlikes;

  SuperlikeResponse({
    required this.isMatch,
    this.match,
    this.message,
    this.remainingSuperlikes,
  });

  factory SuperlikeResponse.fromJson(Map<String, dynamic> json) {
    return SuperlikeResponse(
      isMatch: json['is_match'] as bool? ?? false,
      match: json['match'] != null
          ? Match.fromJson(json['match'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
      remainingSuperlikes: json['remaining_superlikes'] as int?,
    );
  }
}
