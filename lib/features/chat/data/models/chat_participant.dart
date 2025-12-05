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
    // Get user ID
    int userId = 0;
    if (json['user_id'] != null) {
      userId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    }
    
    // Get first name - provide default if missing
    String firstName = json['first_name']?.toString() ?? 
                       json['name']?.toString() ?? 
                       'User';
    
    return ChatParticipant(
      userId: userId,
      firstName: firstName,
      lastName: json['last_name']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'].toString())
          : null,
      isTyping: json['is_typing'] == true || json['is_typing'] == 1,
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
