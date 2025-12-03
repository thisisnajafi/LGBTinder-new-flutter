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
    return FavoriteUser(
      id: json['id'] as int? ?? json['favorite_id'] as int? ?? 0,
      favoriteUserId: json['favorite_user_id'] as int? ?? json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      primaryImageUrl: json['primary_image_url'] as String? ?? json['image_url'] as String?,
      note: json['note'] as String?,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
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

