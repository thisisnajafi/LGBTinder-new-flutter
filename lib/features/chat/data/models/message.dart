/// Message model
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
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      attachmentUrl: json['attachment_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

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
