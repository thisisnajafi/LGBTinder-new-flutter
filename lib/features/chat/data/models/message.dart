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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('Message.fromJson: id is required but was null');
    }
    if (json['sender_id'] == null) {
      throw FormatException('Message.fromJson: sender_id is required but was null');
    }
    if (json['receiver_id'] == null) {
      throw FormatException('Message.fromJson: receiver_id is required but was null');
    }
    if (json['message'] == null) {
      throw FormatException('Message.fromJson: message is required but was null');
    }
    
    return Message(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      senderId: (json['sender_id'] is int) ? json['sender_id'] as int : int.parse(json['sender_id'].toString()),
      receiverId: (json['receiver_id'] is int) ? json['receiver_id'] as int : int.parse(json['receiver_id'].toString()),
      message: json['message'].toString(),
      messageType: json['message_type']?.toString() ?? 'text',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      attachmentUrl: json['attachment_url']?.toString(),
      metadata: json['metadata'] != null && json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
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
