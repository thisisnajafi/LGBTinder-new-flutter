/// Chat participant model
class ChatParticipant {
  final int userId;
  final String firstName;
  final String? lastName;
  final String? primaryImageUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isTyping;

  ChatParticipant({
    required this.userId,
    required this.firstName,
    this.lastName,
    this.primaryImageUrl,
    this.isOnline = false,
    this.lastSeen,
    this.isTyping = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      primaryImageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      isTyping: json['is_typing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      'is_online': isOnline,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      'is_typing': isTyping,
    };
  }
}
