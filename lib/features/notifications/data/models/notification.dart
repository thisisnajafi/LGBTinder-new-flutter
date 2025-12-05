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
    // Validate required fields
    if (json['id'] == null) {
      throw FormatException('Notification.fromJson: id is required but was null');
    }
    if (json['type'] == null) {
      throw FormatException('Notification.fromJson: type is required but was null');
    }
    
    return Notification(
      id: (json['id'] is int) ? json['id'] as int : int.parse(json['id'].toString()),
      type: json['type'].toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      data: json['data'] != null && json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      userId: json['user_id'] != null ? ((json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString())) : null,
      userImageUrl: json['user_image_url']?.toString() ?? json['image_url']?.toString(),
      actionUrl: json['action_url']?.toString(),
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
