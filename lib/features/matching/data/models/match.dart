import '../../../profile/data/models/user_profile.dart';

/// Match model
class Match {
  final int id;
  final int userId;
  final String firstName;
  final String? lastName;
  final String? profileBio;
  final String? primaryImageUrl;
  final List<String>? imageUrls;
  final DateTime matchedAt;
  final bool? isRead;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int? unreadCount;

  Match({
    required this.id,
    required this.userId,
    required this.firstName,
    this.lastName,
    this.profileBio,
    this.primaryImageUrl,
    this.imageUrls,
    required this.matchedAt,
    this.isRead,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as int? ?? json['match_id'] as int? ?? 0,
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      profileBio: json['profile_bio'] as String?,
      primaryImageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      imageUrls: json['images'] != null
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : null,
      matchedAt: json['matched_at'] != null
          ? DateTime.parse(json['matched_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (profileBio != null) 'profile_bio': profileBio,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      if (imageUrls != null) 'images': imageUrls,
      'matched_at': matchedAt.toIso8601String(),
      if (isRead != null) 'is_read': isRead,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt!.toIso8601String(),
      if (unreadCount != null) 'unread_count': unreadCount,
    };
  }
}
