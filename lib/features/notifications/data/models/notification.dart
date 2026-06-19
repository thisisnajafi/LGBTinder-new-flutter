import 'dart:convert';

/// Notification model
/// FIXED: Updated to handle backend response structure with nested from_user object
class Notification {
  final int id;
  final String type; // 'like', 'match', 'message', 'superlike', etc.
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data (user_id, match_id, etc.)
  final int? userId;
  final String? userName;
  final String? userImageUrl;
  final String? actionUrl; // Deep link or route
  final bool isPlanRestricted;
  final bool upgradeRequired;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.userId,
    this.userName,
    this.userImageUrl,
    this.actionUrl,
    this.isPlanRestricted = false,
    this.upgradeRequired = false,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Use default values instead of throwing on missing id/type
    // This prevents list parsing from crashing on a single malformed notification
    final id = json['id'] != null 
        ? ((json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0)
        : 0;
    final type = json['type']?.toString() ?? 'unknown';
    
    // FIXED: Extract user info from nested 'from_user' object (backend response structure)
    int? userId;
    String? userName;
    String? userImageUrl;
    
    if (json['from_user'] != null && json['from_user'] is Map) {
      final fromUser = json['from_user'] as Map<String, dynamic>;
      // from_user.id may be null for anonymous/plan-restricted notifications
      if (fromUser['id'] != null) {
        userId = (fromUser['id'] is int) 
            ? fromUser['id'] as int 
            : int.tryParse(fromUser['id'].toString());
      }
      userName = fromUser['name']?.toString();
      userImageUrl = fromUser['avatar']?.toString();
    }
    
    // Fallback to direct fields if from_user not present
    userId ??= json['user_id'] != null
        ? ((json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()))
        : null;

    // Backend stores actor id in notifications.data JSON (e.g. plan-restricted likes)
    if (userId == null && json['data'] != null) {
      Map<String, dynamic>? dataMap;
      final rawData = json['data'];
      if (rawData is Map) {
        dataMap = Map<String, dynamic>.from(rawData);
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(rawData);
          if (parsed is Map) {
            dataMap = Map<String, dynamic>.from(parsed);
          }
        } catch (_) {}
      }
      final rawId = dataMap?['user_id'] ?? dataMap?['sender_id'] ?? dataMap?['from_user_id'];
      if (rawId != null) {
        userId = rawId is int ? rawId : int.tryParse(rawId.toString());
      }
    }
    userImageUrl ??= json['user_image_url']?.toString() ?? json['image_url']?.toString();

    final dataMap = _parseDataField(json['data']);
    if (userImageUrl == null && dataMap != null) {
      for (final key in const [
        'avatar_url',
        'user_avatar',
        'from_user_avatar',
        'profile_image',
      ]) {
        final candidate = dataMap[key]?.toString();
        if (candidate != null && candidate.isNotEmpty) {
          userImageUrl = candidate;
          break;
        }
      }
    }
    if (userName == null && dataMap != null) {
      userName = dataMap['user_name']?.toString() ?? dataMap['name']?.toString();
    }
    
    // FIXED: Check both 'is_read' and 'read_at' for read status
    final isRead = json['is_read'] == true || 
                   json['is_read'] == 1 || 
                   json['read_at'] != null;
    
    return Notification(
      id: id,
      type: type,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: isRead,
      data: dataMap,
      userId: userId,
      userName: userName,
      userImageUrl: userImageUrl,
      actionUrl: json['action_url']?.toString(),
      isPlanRestricted: json['is_plan_restricted'] == true || json['is_plan_restricted'] == 1,
      upgradeRequired: json['upgrade_required'] == true || json['upgrade_required'] == 1,
    );
  }

  static Map<String, dynamic>? _parseDataField(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (_) {}
    }
    return null;
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
      if (userName != null) 'user_name': userName,
      if (userImageUrl != null) 'user_image_url': userImageUrl,
      if (actionUrl != null) 'action_url': actionUrl,
      'is_plan_restricted': isPlanRestricted,
      'upgrade_required': upgradeRequired,
    };
  }
}

/// Paginated notifications list from GET /notifications.
class NotificationsPageResult {
  final List<Notification> notifications;
  final bool hasMore;
  final int unreadCount;

  const NotificationsPageResult({
    this.notifications = const [],
    this.hasMore = false,
    this.unreadCount = 0,
  });

  static const empty = NotificationsPageResult();
}
