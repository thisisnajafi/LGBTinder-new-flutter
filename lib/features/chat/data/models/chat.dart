import 'message.dart';

/// Chat conversation model
class Chat {
  final int id;
  final int userId;
  final String firstName;
  final String? lastName;
  final String? primaryImageUrl;
  final Message? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isTyping;
  final bool isMuted;

  Chat({
    required this.id,
    required this.userId,
    required this.firstName,
    this.lastName,
    this.primaryImageUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.isTyping = false,
    this.isMuted = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Get ID from multiple possible fields
    int chatId = 0;
    if (json['id'] != null) {
      chatId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['chat_id'] != null) {
      chatId = (json['chat_id'] is int) ? json['chat_id'] as int : int.tryParse(json['chat_id'].toString()) ?? 0;
    }
    
    // Get user ID (other user in conversation). Backend getChatUsers returns 'id' for the other user, not 'user_id'.
    int userId = 0;
    if (json['user_id'] != null) {
      userId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    } else if (json['id'] != null) {
      userId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    }

    final rawFirst = json['first_name']?.toString().trim() ?? '';
    final rawLast = json['last_name']?.toString().trim() ?? '';
    final rawName = json['name']?.toString().trim() ?? '';
    final rawDisplay = json['display_name']?.toString().trim() ?? '';
    final rawUsername = json['username']?.toString().trim() ?? '';

    String firstName;
    String? lastName;
    if (rawFirst.isNotEmpty) {
      firstName = rawFirst;
      lastName = rawLast.isNotEmpty ? rawLast : null;
    } else if (rawName.isNotEmpty) {
      final parts = rawName.split(RegExp(r'\s+'));
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    } else if (rawDisplay.isNotEmpty) {
      final parts = rawDisplay.split(RegExp(r'\s+'));
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    } else if (rawUsername.isNotEmpty) {
      firstName = rawUsername;
      lastName = null;
    } else {
      final nestedUser = json['user'] ?? json['peer'] ?? json['other_user'];
      if (nestedUser is Map) {
        final nested = Map<String, dynamic>.from(nestedUser);
        return Chat.fromJson({...json, ...nested});
      }
      firstName = 'User';
      lastName = null;
    }

    return Chat(
      id: chatId,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString() ?? json['avatar_url']?.toString(),
      lastMessage: json['last_message'] != null && json['last_message'] is Map
          ? Message.fromJson(Map<String, dynamic>.from(json['last_message'] as Map))
          : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      unreadCount: json['unread_count'] != null ? ((json['unread_count'] is int) ? json['unread_count'] as int : int.tryParse(json['unread_count'].toString()) ?? 0) : 0,
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'].toString())
          : null,
      isTyping: json['is_typing'] == true || json['is_typing'] == 1,
      isMuted: json['is_muted'] == true || json['is_muted'] == 1,
    );
  }

  /// Display name for list rows and headers.
  String get displayName {
    final first = firstName.trim();
    final last = lastName?.trim() ?? '';
    if (first.isEmpty) return 'User';
    if (last.isEmpty) return first;
    return '$first $last';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      if (lastMessage != null) 'last_message': lastMessage!.toJson(),
      if (lastMessageAt != null) 'last_message_at': lastMessageAt!.toIso8601String(),
      'unread_count': unreadCount,
      'is_online': isOnline,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      'is_typing': isTyping,
      'is_muted': isMuted,
    };
  }
}
