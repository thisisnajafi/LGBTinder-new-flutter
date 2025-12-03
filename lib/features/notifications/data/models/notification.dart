/// Notification model
class Notification {
  final int id;
  final String type; // 'like', 'match', 'message', 'superlike', etc.
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data (user_id, match_id, etc.)
  final int? userId;
  final String? userImageUrl;
  final String? actionUrl; // Deep link or route

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.userId,
    this.userImageUrl,
    this.actionUrl,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      userId: json['user_id'] as int?,
      userImageUrl: json['user_image_url'] as String? ?? json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      if (data != null) 'data': data,
      if (userId != null) 'user_id': userId,
      if (userImageUrl != null) 'user_image_url': userImageUrl,
      if (actionUrl != null) 'action_url': actionUrl,
    };
  }
}
