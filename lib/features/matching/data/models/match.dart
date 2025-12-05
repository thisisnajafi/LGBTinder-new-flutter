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
    // Validate required fields
    if (json['user_id'] == null) {
      throw FormatException('Match.fromJson: user_id is required but was null');
    }
    if (json['first_name'] == null) {
      throw FormatException('Match.fromJson: first_name is required but was null');
    }
    
    // Get ID from multiple possible fields
    int matchId = 0;
    if (json['id'] != null) {
      matchId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['match_id'] != null) {
      matchId = (json['match_id'] is int) ? json['match_id'] as int : int.tryParse(json['match_id'].toString()) ?? 0;
    }
    
    return Match(
      id: matchId,
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      firstName: json['first_name'].toString(),
      lastName: json['last_name']?.toString(),
      profileBio: json['profile_bio']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
      imageUrls: json['images'] != null && json['images'] is List
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : null,
      matchedAt: json['matched_at'] != null
          ? (DateTime.tryParse(json['matched_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      unreadCount: json['unread_count'] != null ? ((json['unread_count'] is int) ? json['unread_count'] as int : int.tryParse(json['unread_count'].toString())) : null,
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
