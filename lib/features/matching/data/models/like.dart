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
    // Get ID from multiple possible fields
    int likeId = 0;
    if (json['id'] != null) {
      likeId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['like_id'] != null) {
      likeId = (json['like_id'] is int) ? json['like_id'] as int : int.tryParse(json['like_id'].toString()) ?? 0;
    }
    
    // Get user ID
    int likedUserId = 0;
    if (json['liked_user_id'] != null) {
      likedUserId = (json['liked_user_id'] is int) ? json['liked_user_id'] as int : int.tryParse(json['liked_user_id'].toString()) ?? 0;
    } else if (json['user_id'] != null) {
      likedUserId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    }
    
    // Get first name - provide default if missing
    String firstName = json['first_name']?.toString() ?? 
                       json['name']?.toString() ?? 
                       'User $likedUserId';
    
    return Like(
      id: likeId,
      likedUserId: likedUserId,
      firstName: firstName,
      lastName: json['last_name']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
      likedAt: json['liked_at'] != null
          ? (DateTime.tryParse(json['liked_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isSuperlike: json['is_superlike'] == true || json['is_superlike'] == 1,
      isMatch: json['is_match'] == true || json['is_match'] == 1,
      hasResponded: json['has_responded'] == true || json['has_responded'] == 1,
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
      isMatch: json['is_match'] == true || json['is_match'] == 1,
      match: json['match'] != null && json['match'] is Map
          ? match_models.Match.fromJson(Map<String, dynamic>.from(json['match'] as Map))
          : null,
      message: json['message']?.toString(),
    );
  }
}
