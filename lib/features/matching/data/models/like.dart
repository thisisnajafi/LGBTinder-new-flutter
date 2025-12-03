import 'match.dart' as match_models;

/// Like model
class Like {
  final int id;
  final int likedUserId;
  final String firstName;
  final String? lastName;
  final String? primaryImageUrl;
  final DateTime likedAt;
  final bool? isSuperlike;
  final bool? isMatch;
  final bool? hasResponded;

  Like({
    required this.id,
    required this.likedUserId,
    required this.firstName,
    this.lastName,
    this.primaryImageUrl,
    required this.likedAt,
    this.isSuperlike = false,
    this.isMatch = false,
    this.hasResponded = false,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] as int? ?? json['like_id'] as int? ?? 0,
      likedUserId: json['liked_user_id'] as int? ?? json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      primaryImageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      likedAt: json['liked_at'] != null
          ? DateTime.parse(json['liked_at'] as String)
          : DateTime.now(),
      isSuperlike: json['is_superlike'] as bool? ?? false,
      isMatch: json['is_match'] as bool? ?? false,
      hasResponded: json['has_responded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liked_user_id': likedUserId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      'liked_at': likedAt.toIso8601String(),
      'is_superlike': isSuperlike,
      'is_match': isMatch,
      'has_responded': hasResponded,
    };
  }
}

/// Like action request
class LikeActionRequest {
  final int likedUserId;

  LikeActionRequest({required this.likedUserId});

  Map<String, dynamic> toJson() {
    return {'liked_user_id': likedUserId};
  }
}

/// Like response (for match detection)
class LikeResponse {
  final bool isMatch;
  final match_models.Match? match;
  final String? message;

  LikeResponse({
    required this.isMatch,
    this.match,
    this.message,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      isMatch: json['is_match'] as bool? ?? false,
      match: json['match'] != null
          ? match_models.Match.fromJson(json['match'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}
