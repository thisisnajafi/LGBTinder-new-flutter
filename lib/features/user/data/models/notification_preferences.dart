/// Safe boolean parsing helper
/// FIXED: Task 5.2.1 - Added safe type parsing for notification preferences
bool? _safeParseBoolNullable(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return null;
}

/// Notification preferences model
class NotificationPreferences {
  final bool? emailNotifications;
  final bool? pushNotifications;
  final bool? smsNotifications;
  final bool? matchNotifications;
  final bool? messageNotifications;
  final bool? likeNotifications;

  NotificationPreferences({
    this.emailNotifications,
    this.pushNotifications,
    this.smsNotifications,
    this.matchNotifications,
    this.messageNotifications,
    this.likeNotifications,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (emailNotifications != null) json['email_notifications'] = emailNotifications;
    if (pushNotifications != null) json['push_notifications'] = pushNotifications;
    if (smsNotifications != null) json['sms_notifications'] = smsNotifications;
    if (matchNotifications != null) json['match_notifications'] = matchNotifications;
    if (messageNotifications != null) json['message_notifications'] = messageNotifications;
    if (likeNotifications != null) json['like_notifications'] = likeNotifications;
    return json;
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailNotifications: _safeParseBoolNullable(json['email_notifications']),
      pushNotifications: _safeParseBoolNullable(json['push_notifications']),
      smsNotifications: _safeParseBoolNullable(json['sms_notifications']),
      matchNotifications: _safeParseBoolNullable(json['match_notifications']),
      messageNotifications: _safeParseBoolNullable(json['message_notifications']),
      likeNotifications: _safeParseBoolNullable(json['like_notifications']),
    );
  }
}

