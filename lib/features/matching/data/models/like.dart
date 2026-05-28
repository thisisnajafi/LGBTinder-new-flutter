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
  final String? message;

  LikeActionRequest({required this.likedUserId, this.message});

  Map<String, dynamic> toJson() {
    return {
      'target_user_id': likedUserId,
      if (message != null && message!.trim().isNotEmpty) 'message': message!.trim(),
    };
  }
}

/// Like response (for match detection)
class SuperlikeSubscriptionSnapshot {
  final String tier;
  final bool isActive;
  final int superlikesPerDay;
  final int superlikesUsedToday;

  const SuperlikeSubscriptionSnapshot({
    required this.tier,
    required this.isActive,
    required this.superlikesPerDay,
    required this.superlikesUsedToday,
  });

  factory SuperlikeSubscriptionSnapshot.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return false;
    }

    return SuperlikeSubscriptionSnapshot(
      tier: json['tier']?.toString() ?? 'basid',
      isActive: parseBool(json['is_active']),
      superlikesPerDay: parseInt(json['superlikes_per_day']),
      superlikesUsedToday: parseInt(json['superlikes_used_today']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'is_active': isActive,
        'superlikes_per_day': superlikesPerDay,
        'superlikes_used_today': superlikesUsedToday,
      };
}

/// Like response (for match detection)
class LikeResponse {
  final bool isMatch;
  final match_models.Match? match;
  final String? message;
  final int? likedUserId;
  final int? superlikesRemaining;
  final SuperlikeSubscriptionSnapshot? subscription;

  LikeResponse({
    required this.isMatch,
    this.match,
    this.message,
    this.likedUserId,
    this.superlikesRemaining,
    this.subscription,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    final subscriptionRaw = json['subscription'];
    return LikeResponse(
      isMatch: json['is_match'] == true || json['is_match'] == 1,
      match: json['match'] != null && json['match'] is Map
          ? match_models.Match.fromJson(Map<String, dynamic>.from(json['match'] as Map))
          : null,
      message: json['message']?.toString(),
      likedUserId: json['liked_user_id'] != null
          ? int.tryParse(json['liked_user_id'].toString())
          : null,
      superlikesRemaining: json['superlikes_remaining'] != null
          ? int.tryParse(json['superlikes_remaining'].toString())
          : null,
      subscription: subscriptionRaw is Map<String, dynamic>
          ? SuperlikeSubscriptionSnapshot.fromJson(subscriptionRaw)
          : null,
    );
  }
}

/// Response from dislike endpoint. [theyLikedYou] when the other user had liked us (we passed on them).
class DislikeResponse {
  final bool theyLikedYou;

  DislikeResponse({this.theyLikedYou = false});
}

/// Response from likes/rewind (undo last like/dislike). Premium only.
class RewindResponse {
  final Map<String, dynamic>? restoredUser;
  final String? actionUndone;
  final int? remainingRewinds;

  RewindResponse({
    this.restoredUser,
    this.actionUndone,
    this.remainingRewinds,
  });
}
