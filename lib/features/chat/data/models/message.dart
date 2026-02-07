/// Safe integer parsing helper
int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Safe boolean parsing helper
bool _safeParseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// Safe DateTime parsing helper
DateTime? _safeParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Message model
/// FIXED: Task 5.3.1 - Removed strict validation that throws exceptions
class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final String messageType; // 'text', 'image', 'voice', 'video', etc.
  final DateTime createdAt;
  final bool isRead;
  final bool isDeleted;
  final String? attachmentUrl;
  final Map<String, dynamic>? metadata;
  /// When true (free user, message from non-match): show blurred "You have a new message" in UI.
  final bool isLocked;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    required this.createdAt,
    this.isRead = false,
    this.isDeleted = false,
    this.attachmentUrl,
    this.metadata,
    this.isLocked = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // FIXED: Use safe parsing with defaults instead of throwing exceptions
    // This prevents list parsing from crashing on a single malformed item
    return Message(
      id: _safeParseInt(json['id']),
      senderId: _safeParseInt(json['sender_id']),
      receiverId: _safeParseInt(json['receiver_id']),
      message: json['message']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      createdAt: _safeParseDateTime(json['created_at']) ?? DateTime.now(),
      isRead: _safeParseBool(json['is_read']),
      isDeleted: _safeParseBool(json['is_deleted']),
      attachmentUrl: json['attachment_url']?.toString(),
      metadata: json['metadata'] != null && json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      isLocked: _safeParseBool(json['is_locked']),
    );
  }
  
  /// Check if message data is valid (has required fields)
  bool get isValid => id > 0 && senderId > 0 && receiverId > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_deleted': isDeleted,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (metadata != null) 'metadata': metadata,
      'is_locked': isLocked,
    };
  }
}

/// Send message request
class SendMessageRequest {
  final int receiverId;
  final String message;
  final String messageType;

  SendMessageRequest({
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
  });

  Map<String, dynamic> toJson() {
    return {
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
    };
  }
}
