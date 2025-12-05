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
    // Validate required fields
    if (json['first_name'] == null) {
      throw FormatException('Superlike.fromJson: first_name is required but was null');
    }
    
    // Get ID from multiple possible fields
    int superlikeId = 0;
    if (json['id'] != null) {
      superlikeId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['superlike_id'] != null) {
      superlikeId = (json['superlike_id'] is int) ? json['superlike_id'] as int : int.tryParse(json['superlike_id'].toString()) ?? 0;
    }
    
    // Get user ID - validate it exists
    int superlikedUserId;
    if (json['superliked_user_id'] != null) {
      superlikedUserId = (json['superliked_user_id'] is int) ? json['superliked_user_id'] as int : int.parse(json['superliked_user_id'].toString());
    } else if (json['user_id'] != null) {
      superlikedUserId = (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString());
    } else {
      throw FormatException('Superlike.fromJson: superliked_user_id (or user_id) is required but was null');
    }
    
    return Superlike(
      id: superlikeId,
      superlikedUserId: superlikedUserId,
      firstName: json['first_name'].toString(),
      lastName: json['last_name']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
      superlikedAt: json['superliked_at'] != null
          ? (DateTime.tryParse(json['superliked_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isMatch: json['is_match'] == true || json['is_match'] == 1,
      hasResponded: json['has_responded'] == true || json['has_responded'] == 1,
      remainingSuperlikes: json['remaining_superlikes'] != null ? ((json['remaining_superlikes'] is int) ? json['remaining_superlikes'] as int : int.tryParse(json['remaining_superlikes'].toString())) : null,
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
      isMatch: json['is_match'] == true || json['is_match'] == 1,
      match: json['match'] != null && json['match'] is Map
          ? Match.fromJson(Map<String, dynamic>.from(json['match'] as Map))
          : null,
      message: json['message']?.toString(),
      remainingSuperlikes: json['remaining_superlikes'] != null ? ((json['remaining_superlikes'] is int) ? json['remaining_superlikes'] as int : int.tryParse(json['remaining_superlikes'].toString())) : null,
    );
  }
}
