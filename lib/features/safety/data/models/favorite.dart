/// Favorite user model
class FavoriteUser {
  final int id;
  final int favoriteUserId;
  final String firstName;
  final String? lastName;
  final String? primaryImageUrl;
  final String? note;
  final DateTime addedAt;

  FavoriteUser({
    required this.id,
    required this.favoriteUserId,
    required this.firstName,
    this.lastName,
    this.primaryImageUrl,
    this.note,
    required this.addedAt,
  });

  factory FavoriteUser.fromJson(Map<String, dynamic> json) {
    // Get ID from multiple possible fields
    int favoriteId = 0;
    if (json['id'] != null) {
      favoriteId = (json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0;
    } else if (json['favorite_id'] != null) {
      favoriteId = (json['favorite_id'] is int) ? json['favorite_id'] as int : int.tryParse(json['favorite_id'].toString()) ?? 0;
    }
    
    // Get user ID
    int favoriteUserId = 0;
    if (json['favorite_user_id'] != null) {
      favoriteUserId = (json['favorite_user_id'] is int) ? json['favorite_user_id'] as int : int.tryParse(json['favorite_user_id'].toString()) ?? 0;
    } else if (json['user_id'] != null) {
      favoriteUserId = (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id'].toString()) ?? 0;
    }
    
    // Get first name - provide default if missing
    String firstName = json['first_name']?.toString() ?? 
                       json['name']?.toString() ?? 
                       'Favorite User';
    
    return FavoriteUser(
      id: favoriteId,
      favoriteUserId: favoriteUserId,
      firstName: firstName,
      lastName: json['last_name']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString() ?? json['image_url']?.toString(),
      note: json['note']?.toString(),
      addedAt: json['added_at'] != null
          ? (DateTime.tryParse(json['added_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'favorite_user_id': favoriteUserId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (primaryImageUrl != null) 'primary_image_url': primaryImageUrl,
      if (note != null) 'note': note,
      'added_at': addedAt.toIso8601String(),
    };
  }
}

/// Add to favorites request
class AddFavoriteRequest {
  final int favoriteUserId;
  final String? note;

  AddFavoriteRequest({
    required this.favoriteUserId,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'favorite_user_id': favoriteUserId,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}

