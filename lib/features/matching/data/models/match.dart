import 'package:equatable/equatable.dart';

import '../../../../core/utils/media_url.dart';

/// Match model
class Match extends Equatable {
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

  const Match({
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
    json = _flattenNestedUser(json);

    // Get ID from multiple possible fields
    int matchId = 0;
    if (json['match_id'] != null) {
      matchId = (json['match_id'] is int) ? json['match_id'] as int : int.tryParse(json['match_id'].toString()) ?? 0;
    } else if (json['id'] != null) {
      matchId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    }
    
    // Get user ID — backend match list historically sends the peer as `id`
    int userId = 0;
    if (json['user_id'] != null) {
      userId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    } else if (json['id'] != null) {
      userId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    }
    
    // Get first name - provide default if missing
    String firstName = json['first_name']?.toString() ?? 
                       json['name']?.toString() ?? 
                       'Match';
    
    return Match(
      id: matchId,
      userId: userId,
      firstName: firstName,
      lastName: json['last_name']?.toString(),
      profileBio: json['profile_bio']?.toString(),
      primaryImageUrl: _photoUrl(json),
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

  static String? _photoUrl(Map<String, dynamic> json) {
    for (final key in const [
      'primary_image_url',
      'image_url',
      'avatar_url',
      'avatar',
    ]) {
      final value = json[key]?.toString();
      if (value == null || MediaUrl.isPlaceholder(value)) continue;
      return value;
    }
    return null;
  }

  static Map<String, dynamic> _flattenNestedUser(Map<String, dynamic> json) {
    final nestedUser = json['user'];
    if (nestedUser is! Map) return json;

    final userMap = Map<String, dynamic>.from(nestedUser);
    return {
      ...userMap,
      ...json,
      'user_id': json['user_id'] ?? userMap['id'] ?? userMap['user_id'],
      'first_name': json['first_name'] ?? userMap['first_name'] ?? userMap['name'],
      'last_name': json['last_name'] ?? userMap['last_name'],
      'primary_image_url': json['primary_image_url'] ??
          json['avatar_url'] ??
          json['avatar'] ??
          userMap['primary_image_url'] ??
          userMap['avatar_url'] ??
          userMap['avatar'],
    };
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

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        profileBio,
        primaryImageUrl,
        imageUrls,
        matchedAt,
        isRead,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}
