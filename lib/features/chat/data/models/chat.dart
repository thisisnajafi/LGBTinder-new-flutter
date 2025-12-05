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
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['user_id'] == null) {
      throw FormatException('Chat.fromJson: user_id is required but was null');
    }
    if (json['first_name'] == null) {
      throw FormatException('Chat.fromJson: first_name is required but was null');
    }
    
    // Get ID from multiple possible fields
    int chatId = 0;
    if (json['id'] != null) {
      chatId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['chat_id'] != null) {
      chatId = (json['chat_id'] is int) ? json['chat_id'] as int : int.tryParse(json['chat_id'].toString()) ?? 0;
    }
    
    return Chat(
      id: chatId,
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      firstName: json['first_name'].toString(),
      lastName: json['last_name']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
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
    );
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
    };
  }
}
