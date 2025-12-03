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
      emailNotifications: json['email_notifications'] as bool?,
      pushNotifications: json['push_notifications'] as bool?,
      smsNotifications: json['sms_notifications'] as bool?,
      matchNotifications: json['match_notifications'] as bool?,
      messageNotifications: json['message_notifications'] as bool?,
      likeNotifications: json['like_notifications'] as bool?,
    );
  }
}

