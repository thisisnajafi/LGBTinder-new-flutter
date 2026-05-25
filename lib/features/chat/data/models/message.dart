import 'message_delivery_status.dart';

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
  /// When true (basid tier): message content is hidden beyond visibility limit.
  final bool isBlurred;
  /// Client-generated id for optimistic messages (replaced after API success).
  final String? clientId;
  final MessageDeliveryStatus deliveryStatus;
  final String? mediaThumbnailUrl;
  final int? mediaWidth;
  final int? mediaHeight;
  final Map<String, dynamic>? profileCard;
  final int? remainingSeconds;
  final bool isExpired;
  final DateTime? viewedAt;
  final String? secureMediaUrl;
  final int? mediaDuration;

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
    this.isBlurred = false,
    this.clientId,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.mediaThumbnailUrl,
    this.mediaWidth,
    this.mediaHeight,
    this.profileCard,
    this.remainingSeconds,
    this.isExpired = false,
    this.viewedAt,
    this.secureMediaUrl,
    this.mediaDuration,
  });

  bool get isOptimistic => clientId != null && id <= 0;

  /// Local placeholder shown before the API responds.
  factory Message.optimistic({
    required String clientId,
    required int senderId,
    required int receiverId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
  }) {
    return Message(
      id: 0,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      messageType: messageType,
      createdAt: DateTime.now(),
      attachmentUrl: attachmentUrl,
      clientId: clientId,
      deliveryStatus: MessageDeliveryStatus.sending,
    );
  }

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? message,
    String? messageType,
    DateTime? createdAt,
    bool? isRead,
    bool? isDeleted,
    String? attachmentUrl,
    Map<String, dynamic>? metadata,
    bool? isLocked,
    bool? isBlurred,
    String? clientId,
    bool clearClientId = false,
    MessageDeliveryStatus? deliveryStatus,
    String? mediaThumbnailUrl,
    int? mediaWidth,
    int? mediaHeight,
    Map<String, dynamic>? profileCard,
    int? remainingSeconds,
    bool? isExpired,
    DateTime? viewedAt,
    String? secureMediaUrl,
    int? mediaDuration,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      metadata: metadata ?? this.metadata,
      isLocked: isLocked ?? this.isLocked,
      isBlurred: isBlurred ?? this.isBlurred,
      clientId: clearClientId ? null : (clientId ?? this.clientId),
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      profileCard: profileCard ?? this.profileCard,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isExpired: isExpired ?? this.isExpired,
      viewedAt: viewedAt ?? this.viewedAt,
      secureMediaUrl: secureMediaUrl ?? this.secureMediaUrl,
      mediaDuration: mediaDuration ?? this.mediaDuration,
    );
  }

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
      attachmentUrl: json['attachment_url']?.toString() ??
          json['media_url']?.toString(),
      metadata: json['metadata'] != null && json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : (json['sticker'] is Map
              ? Map<String, dynamic>.from(json['sticker'] as Map)
              : null),
      isLocked: _safeParseBool(json['is_locked']),
      isBlurred: _safeParseBool(json['is_blurred']),
      clientId: json['client_id']?.toString(),
      deliveryStatus: _parseDeliveryStatus(json['delivery_status']),
      mediaThumbnailUrl: json['media_thumbnail_url']?.toString(),
      mediaWidth: json['media_width'] != null || json['width'] != null
          ? _safeParseInt(json['media_width'] ?? json['width'], defaultValue: 0)
          : null,
      mediaHeight: json['media_height'] != null || json['height'] != null
          ? _safeParseInt(json['media_height'] ?? json['height'], defaultValue: 0)
          : null,
      profileCard: json['profile_card'] is Map
          ? Map<String, dynamic>.from(json['profile_card'] as Map)
          : null,
      remainingSeconds: json['remaining_seconds'] != null
          ? _safeParseInt(json['remaining_seconds'])
          : null,
      isExpired: _safeParseBool(json['is_expired']),
      viewedAt: _safeParseDateTime(json['viewed_at']),
      secureMediaUrl: json['secure_media_url']?.toString(),
      mediaDuration: json['media_duration'] != null || json['duration_seconds'] != null
          ? _safeParseInt(json['media_duration'] ?? json['duration_seconds'])
          : null,
    );
  }

  static MessageDeliveryStatus _parseDeliveryStatus(dynamic value) {
    if (value == null) return MessageDeliveryStatus.sent;
    final normalized = value.toString().toLowerCase();
    switch (normalized) {
      case 'sending':
        return MessageDeliveryStatus.sending;
      case 'queued':
        return MessageDeliveryStatus.queued;
      case 'failed':
        return MessageDeliveryStatus.failed;
      default:
        return MessageDeliveryStatus.sent;
    }
  }
  
  /// Check if message data is valid (has required fields)
  bool get isValid =>
      senderId > 0 && receiverId > 0 && (id > 0 || clientId != null);

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
      if (clientId != null) 'client_id': clientId,
      'delivery_status': deliveryStatus.name,
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
